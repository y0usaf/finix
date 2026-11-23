import { readdirSync } from "node:fs";
import { col, Form, getKeybindings, node, Spacer, span, Text, TextFormField } from "@oh-my-pi/pi-tui";
import { boundKeys, editorKey, interruptKey, OverlayPanel } from "@oh-my-pi/pi-tui/chrome";
import { formTheme } from "@oh-my-pi/pi-tui/chrome/form-theme";
import { matchesAppInterrupt } from "@oh-my-pi/pi-tui/keybinding-matchers";
import { actionBar, actionButton } from "@oh-my-pi/pi-tui/native/overlay";
import { current, dir, forget, held, label, list, meta, modified, NAME, pending, request, reveal, type Scope, settle, store, ttl } from "./store";

const WAIT_MS = 600_000;

function text(message: string) {
	return { content: [{ type: "text", text: message }], details: {} };
}

class SecretEntry extends OverlayPanel {
	#field;
	#form;
	#title: string;
	#reason: string;
	#cancel: () => void;
	#native: { error: boolean; node: unknown } | undefined;

	constructor(title: string, reason: string, submit: (value: string) => Promise<void>, cancel: () => void, requestRender: () => void) {
		super(title, "omp.overlay.hook-input");
		this.#title = title;
		this.#reason = reason;
		this.#cancel = cancel;
		this.#field = new TextFormField({ theme: formTheme, secret: true, empty: "reject", emptyError: "Type the value, or cancel.", onSubmit: submit, onCancel: cancel, requestRender });
		this.#form = new Form({ fields: [this.#field], onCancel: cancel, isCancel: matchesAppInterrupt });
		this.addChild(new Text(formTheme.hint(reason), 0, 0));
		this.addChild(this.#form);
		this.addChild(new Text(formTheme.hint(`${editorKey("tui.input.submit")} store  ${interruptKey()} cancel`), 0, 0));
		this.addChild(new Spacer(1));
	}

	handleInput(data: string): void {
		this.#form.handleInput(data);
	}

	pasteText(text: string): void {
		this.#form.pasteText(text);
	}

	handleNativeEvent(event: { type: string; act?: string }): void {
		if (event.type !== "action") return;
		if (event.act === "submit") this.#field.submit();
		else if (event.act === "cancel") this.#cancel();
	}

	describe() {
		const error = this.#field.hasError;
		if (this.#native?.error === error) return this.#native.node;
		const submitKey = getKeybindings().getKeys("tui.input.submit")[0];
		const cancelKey = boundKeys("app.interrupt", ["escape"])[0];
		const head = [
			node("text", { spans: [span(this.#title)], role: "omp.hook-input.title", wrap: "word" }, undefined, "title"),
			node("text", { spans: [span(this.#reason)], role: "omp.hook-input.detail", wrap: "word" }, undefined, "detail"),
		];
		const root = col(
			[
				node("col", { role: "omp.hook-input.head", gap: "xs" }, head, "head"),
				node("col", { role: "omp.hook-input.field", ...(error ? { tone: "error" } : {}) }, [this.#form], "field"),
				actionBar([null, actionButton("Cancel", "cancel", cancelKey ? { keys: cancelKey } : {}), actionButton("Store", "submit", { tone: "accent", ...(submitKey ? { keys: submitKey } : {}) })]),
			],
			{ role: this.nativeRole },
		);
		this.#native = { error, node: root };
		return root;
	}
}

export default function secrets(pi) {
	const bot = current();
	const z = pi.zod;
	const known = new Map<string, { mtime: number; value: string }>();
	const seen = new Map<string, string>();
	const showing = new Set<string>();
	const boxed = Boolean(process.env.OMP_SECRETS_DIR);

	pi.setLabel("Secrets");

	async function values(): Promise<[string, string][]> {
		for (const scope of bot ? [bot, undefined] : [undefined]) {
			let files: string[] = [];
			try {
				files = readdirSync(dir(scope)).filter(file => file.endsWith(".age"));
			} catch {}
			for (const file of files) {
				const name = file.slice(0, -4);
				const id = `${label(scope)}/${name}`;
				const mtime = modified(scope, name);
				if (known.get(id)?.mtime === mtime) continue;
				const value = await reveal(scope, name).catch(() => undefined);
				if (value === undefined) continue;
				known.set(id, { mtime, value });
				if (value.length > 0) seen.set(value, name);
			}
		}
		return [...seen].sort((a, b) => b[0].length - a[0].length);
	}

	function scrub(value: unknown, secrets: [string, string][]): unknown {
		if (typeof value === "string") {
			let out = value;
			for (const [secret, name] of secrets) if (out.includes(secret)) out = out.replaceAll(secret, `[SECRET_${name}]`);
			return out;
		}
		if (Array.isArray(value)) {
			let changed = false;
			const out = value.map(item => {
				const next = scrub(item, secrets);
				if (next !== item) changed = true;
				return next;
			});
			return changed ? out : value;
		}
		if (value && typeof value === "object") {
			let changed = false;
			const out: Record<string, unknown> = {};
			for (const [key, item] of Object.entries(value)) {
				const next = scrub(item, secrets);
				if (next !== item) changed = true;
				out[key] = next;
			}
			return changed ? out : value;
		}
		return value;
	}

	async function enter(ctx, scope: Scope, name: string, reason: string, expiry: string | undefined, signal?: AbortSignal): Promise<void> {
		const id = `${label(scope)}/${name}`;
		if (signal?.aborted || showing.has(id)) return;
		showing.add(id);
		const before = meta(scope, name)?.set;
		const stop = new AbortController();
		const abort = () => stop.abort();
		signal?.addEventListener("abort", abort, { once: true });
		const watch = setInterval(() => meta(scope, name)?.set !== before && stop.abort(), 1000);
		const title = `Secret ${name} for ${scope ?? "all bots"} (hidden)`;
		try {
			await ctx.ui.custom(
				(tui, _theme, _keys, done) =>
					new SecretEntry(
						title,
						reason,
						async value => {
							await store(scope, name, value, expiry, reason);
							done(undefined);
						},
						() => {
							settle(scope, name);
							done(undefined);
						},
						() => tui.requestRender(),
					),
				{ signal: stop.signal },
			);
		} catch {
		} finally {
			clearInterval(watch);
			signal?.removeEventListener("abort", abort);
			showing.delete(id);
		}
	}

	pi.registerTool({
		name: "secret",
		label: "Secret",
		description:
			"Manage user-supplied secrets (hidden from you; in bash, `secret run NAME -- CMD` gives CMD $SECRET_NAME and scrubs it from output). action=request (name like GITHUB_TOKEN, one-line reason, optional ttl 30m|12h|7d|never default 24h, optional shared), list, or forget. Never ask for or inspect values.",
		parameters: z.object({
			action: z.enum(["request", "list", "forget"]),
			name: z.string().optional(),
			reason: z.string().optional(),
			ttl: z.string().optional(),
			shared: z.boolean().optional(),
		}),
		async execute(_toolCallId, params, signal, onUpdate, ctx) {
			if (params.action === "list") {
				const mine = list(bot);
				const shared = bot ? list(undefined).filter(found => !mine.some(own => own.name === found.name)) : [];
				if (mine.length + shared.length === 0) return text("You hold no secrets.");
				const line = (found, whose: string) => `${found.name} (use: secret run ${found.name} -- CMD), ${whose}expires ${found.expires === null ? "never" : new Date(found.expires).toISOString()}`;
				return text([...mine.map(found => line(found, "")), ...shared.map(found => line(found, "shared with all bots, "))].join("\n"));
			}
			const name = params.name ?? "";
			if (!NAME.test(name)) return text(`'${name}' is not a secret name: use capitals, digits and _, starting with a capital, like GITHUB_TOKEN.`);
			if (params.action === "forget") {
				if (forget(bot, name)) return text(`Forgot ${name}.`);
				if (bot && meta(undefined, name)) return text(`${name} is shared with all bots by the user; only they can remove it.`);
				return text(`You hold no secret ${name}.`);
			}
			const scope = params.shared ? undefined : bot;
			if (scope === undefined && bot && boxed) return text("A bot in a box can't add a shared secret; ask for your own with shared left out, or the user can ask a bot outside a box to add the shared one.");
			if (scope === undefined ? meta(undefined, name) : held(bot, name)) return text(`${name} is already set; use it with secret run ${name} -- CMD in bash.`);
			const reason = (params.reason ?? "").trim();
			if (!reason) return text("Give a one-line reason so the user knows what the secret is for.");
			try {
				ttl(params.ttl);
			} catch (error) {
				return text(error.message);
			}
			request(scope, name, reason, params.ttl);
			const set = `The user set ${name}. Use it with secret run ${name} -- CMD in bash; you will never see its value.`;
			if (ctx?.mode === "tui") {
				await enter(ctx, scope, name, reason, params.ttl, signal);
				if (held(bot, name)) return text(set);
				if (pending().some(ask => ask.bot === scope && ask.name === name)) return text(`The box for ${name} closed before the user answered; the request stays open and the box opens again when this chat restarts.`);
				return text(`The user cancelled ${name}; the request is closed. Don't ask for it again unless they say so.`);
			}
			onUpdate?.(text(`Waiting for the user to enter ${name} in the masked box, which opens when this chat is open in a terminal`));
			const deadline = Date.now() + WAIT_MS;
			while (Date.now() < deadline && !signal?.aborted) {
				if (held(bot, name)) return text(set);
				if (!pending().some(ask => ask.bot === scope && ask.name === name)) return text(`The user cancelled ${name}; the request is closed. Don't ask for it again unless they say so.`);
				await Bun.sleep(1000);
			}
			return text(`The user hasn't entered ${name} yet; the request stays open, and the masked box opens when they open this chat in a terminal. Tell them so.`);
		},
	});

	pi.on("session_start", (_event, ctx) => {
		if (!bot || ctx.mode !== "tui") return;
		void (async () => {
			for (const ask of pending()) if (ask.bot === bot && !held(bot, ask.name)) await enter(ctx, bot, ask.name, ask.reason, ask.ttl);
		})();
	});

	pi.on("tool_result", async event => {
		const secrets = await values();
		if (secrets.length === 0) return undefined;
		const content = scrub(event.content, secrets);
		const details = scrub(event.details, secrets);
		if (content === event.content && details === event.details) return undefined;
		return { content, details };
	});

	pi.on("context", async event => {
		const secrets = await values();
		if (secrets.length === 0) return undefined;
		const messages = scrub(event.messages, secrets);
		return messages === event.messages ? undefined : { messages };
	});
}
