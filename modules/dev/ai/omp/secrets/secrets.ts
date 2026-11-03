import { readdirSync } from "node:fs";
import { current, dir, forget, label, list, meta, modified, NAME, names, request, reveal, ttl } from "./store";

const WAIT_MS = Number(process.env.OMP_SECRET_WAIT_MS) || 600_000;

function quote(text: string): string {
	return `'${text.replaceAll("'", `'\\''`)}'`;
}

function text(message: string) {
	return { content: [{ type: "text", text: message }], details: {} };
}

export default function secrets(pi) {
	const bot = current();
	const runner = Bun.which("omp-secret");
	const z = pi.zod;
	const known = new Map<string, { mtime: number; value: string }>();
	const seen = new Map<string, string>();

	pi.setLabel("Secrets");

	async function values(): Promise<[string, string][]> {
		let files: string[] = [];
		try {
			files = readdirSync(dir(bot)).filter(file => file.endsWith(".age"));
		} catch {}
		for (const file of files) {
			const name = file.slice(0, -4);
			const mtime = modified(bot, name);
			if (known.get(name)?.mtime === mtime) continue;
			const value = await reveal(bot, name).catch(() => undefined);
			if (value === undefined) continue;
			known.set(name, { mtime, value });
			if (value.length > 0) seen.set(value, name);
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

	pi.registerTool({
		name: "secret",
		label: "Secret",
		description:
			"Secrets (API keys, tokens) the user hands you without you ever seeing them. action request asks the user for secret name (capitals, digits and _, like GITHUB_TOKEN) with a one-line reason and an optional ttl (30m, 12h, 7d or never; default 24h) and waits for them to enter it; list shows the names you hold and when they expire; forget deletes one. Use a secret by writing $SECRET_NAME (e.g. $SECRET_GITHUB_TOKEN) in a bash command: it is set for that command only, and any output containing the value shows the name in brackets instead, like [SECRET_GITHUB_TOKEN]. Never ask for a secret in chat or try to read, print or decode its value.",
		parameters: z.object({
			action: z.enum(["request", "list", "forget"]),
			name: z.string().optional(),
			reason: z.string().optional(),
			ttl: z.string().optional(),
		}),
		async execute(_toolCallId, params, signal, _onUpdate, ctx) {
			if (params.action === "list") {
				const held = list(bot);
				if (held.length === 0) return text("You hold no secrets.");
				return text(held.map(found => `${found.name} (as $SECRET_${found.name}), expires ${found.expires === null ? "never" : new Date(found.expires).toISOString()}`).join("\n"));
			}
			const name = params.name ?? "";
			if (!NAME.test(name)) return text(`'${name}' is not a secret name: use capitals, digits and _, starting with a capital, like GITHUB_TOKEN.`);
			if (params.action === "forget") return text(forget(bot, name) ? `Forgot ${name}.` : `You hold no secret ${name}.`);
			if (meta(bot, name)) return text(`${name} is already set; use $SECRET_${name} in bash.`);
			const reason = (params.reason ?? "").trim();
			if (!reason) return text("Give a one-line reason so the user knows what the secret is for.");
			try {
				ttl(params.ttl);
			} catch (error) {
				return text(error.message);
			}
			request(bot, name, reason, params.ttl);
			ctx?.ui?.notify?.(`${label(bot)} asks for ${name}: ${reason}. Enter it with: omp-secret ${name}`, "info");
			const deadline = Date.now() + WAIT_MS;
			while (Date.now() < deadline && !signal?.aborted) {
				if (meta(bot, name)) return text(`The user set ${name}. Use $SECRET_${name} in bash; you will never see its value.`);
				await Bun.sleep(1000);
			}
			return text(`The user hasn't entered ${name} yet; the request stays open. Tell them to run: omp-secret ${name}`);
		},
	});

	pi.on("tool_call", async event => {
		if (event.toolName !== "bash") return undefined;
		const command = String(event.input?.command ?? "");
		const wanted = names(command);
		if (wanted.length === 0) return undefined;
		if (!runner) return { block: true, reason: "omp-secret is not on PATH, so secrets can't be used here." };
		if (command.startsWith(`${quote(runner)} run <<`)) return undefined;
		const missing = wanted.filter(name => !meta(bot, name));
		if (missing.length > 0) {
			return { block: true, reason: `No secret ${missing.join(", ")} (never set, forgotten or expired). Ask the user for it with the secret tool.` };
		}
		const end = `OMP_SECRET_${crypto.randomUUID().replaceAll("-", "")}`;
		return { input: { ...event.input, command: `${quote(runner)} run <<'${end}'\n${command}\n${end}` } };
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
