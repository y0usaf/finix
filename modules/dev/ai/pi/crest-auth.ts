import {
	type Api,
	type AssistantMessage,
	type AssistantMessageEvent,
	createAssistantMessageEventStream,
	type Model,
	type Provider,
} from "@earendil-works/pi-ai";
import { builtinProviders } from "@earendil-works/pi-ai/providers/all";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { execFile } from "node:child_process";

const PROVIDERS: Readonly<Record<string, true>> = { anthropic: true, "openai-codex": true };

interface Token {
	access: string;
	expires: number;
	login?: string;
}

interface Entry {
	name: string;
	kind: string;
}

const logins = new Map<string, string>();
const WORK = "CU-enterprise";
const WORK_BOT = "CU-Bot";

function crestAuth(...args: string[]): Promise<string> {
	return new Promise((resolve, reject) =>
		execFile("crest-auth", ["json", ...args], (error, stdout, stderr) =>
			error ? reject(new Error(`crest-auth json ${args.join(" ")}: ${stderr.trim() || error.message}`)) : resolve(stdout),
		),
	);
}

async function token(provider: string): Promise<Token> {
	const value: unknown = JSON.parse(await crestAuth("token", provider));
	if (
		typeof value !== "object" ||
		value === null ||
		!("access" in value) ||
		typeof value.access !== "string" ||
		!("expires" in value) ||
		typeof value.expires !== "number"
	) {
		throw new Error(`crest-auth json token ${provider}: no access token`);
	}
	const login = "login" in value && typeof value.login === "string" ? value.login : undefined;
	if (login === WORK && process.env.OMP_BOT_NAME !== WORK_BOT) throw new Error(`crest-auth picked ${WORK}, which is for ${WORK_BOT} only: every login ahead of it is cooling`);
	if (login !== undefined) logins.set(value.access, login);
	return { access: value.access, expires: value.expires, login };
}

async function entries(): Promise<Entry[]> {
	const value: unknown = JSON.parse(await crestAuth("list"));
	if (typeof value !== "object" || value === null || !("logins" in value) || !Array.isArray(value.logins)) {
		throw new Error("crest-auth json list: no logins");
	}
	return value.logins.flatMap((entry: unknown) =>
		typeof entry === "object" &&
		entry !== null &&
		"name" in entry &&
		typeof entry.name === "string" &&
		"kind" in entry &&
		typeof entry.kind === "string"
			? [{ name: entry.name, kind: entry.kind }]
			: [],
	);
}

async function signedIn(): Promise<Set<string>> {
	const providers = new Set<string>();
	for (const entry of await entries()) {
		if (entry.kind === "login") providers.add("anthropic");
		if (entry.kind === "oauth") providers.add(entry.name);
	}
	return providers;
}

const rateLimited = (message: AssistantMessage): boolean =>
	message.stopReason === "error" && /\b429\b|rate.?limit|too many requests|usage limit/i.test(message.errorMessage ?? "");

function failed(model: Model<Api>, error: unknown): AssistantMessage {
	return {
		role: "assistant",
		content: [],
		api: model.api,
		provider: model.provider,
		model: model.id,
		usage: {
			input: 0,
			output: 0,
			cacheRead: 0,
			cacheWrite: 0,
			totalTokens: 0,
			cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 },
		},
		stopReason: "error",
		errorMessage: error instanceof Error ? error.message : String(error),
		timestamp: Date.now(),
	};
}

async function successor(provider: string, spent: ReadonlySet<string>): Promise<Token | undefined> {
	try {
		const next = await token(provider);
		return next.login !== undefined && !spent.has(next.login) ? next : undefined;
	} catch {
		return undefined;
	}
}

function failover(base: Provider): Provider["streamSimple"] {
	return (model, context, options) => {
		const out = createAssistantMessageEventStream();
		const run = async (apiKey: string | undefined, spent: Set<string>): Promise<void> => {
			const held: AssistantMessageEvent[] = [];
			const flush = () => {
				for (const event of held.splice(0)) out.push(event);
			};
			let open = false;
			for await (const event of base.streamSimple(model, context, { ...options, apiKey })) {
				if (event.type === "done" || event.type === "error") {
					const login = apiKey === undefined ? undefined : logins.get(apiKey);
					if (event.type === "error" && !open && login !== undefined && rateLimited(event.error)) {
						spent.add(login);
						await crestAuth("cool", login);
						const next = await successor(base.id, spent);
						if (next !== undefined) return run(next.access, spent);
					}
					flush();
					out.push(event);
					return;
				}
				held.push(event);
				if (open || event.type !== "start") {
					open = true;
					flush();
				}
			}
			flush();
			out.end();
		};
		run(options?.apiKey, new Set()).catch((error) =>
			out.push({ type: "error", reason: "error", error: failed(model, error) }),
		);
		return out;
	};
}

export default async function crest(pi: ExtensionAPI): Promise<void> {
	const providers = await signedIn();
	for (const base of builtinProviders()) {
		const oauth = base.auth.oauth;
		if (!Object.hasOwn(PROVIDERS, base.id) || !providers.has(base.id) || oauth === undefined) continue;
		pi.registerProvider({
			...base,
			auth: {
				apiKey: {
					name: `Crest (${base.name})`,
					check: async () => ({ type: "oauth", source: "crest-auth" }),
					async resolve() {
						const next = await token(base.id);
						return {
							auth: await oauth.toAuth({ type: "oauth", access: next.access, refresh: "", expires: next.expires }),
							source: `crest-auth ${next.login ?? base.id}`,
						};
					},
				},
			},
			streamSimple: failover(base),
		});
	}
}
