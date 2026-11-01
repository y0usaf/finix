import { type ApiKeyResolver, streamSimple } from "@oh-my-pi/pi-ai";
import { getBundledModels } from "@oh-my-pi/pi-catalog/models";
import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

const PROVIDERS = ["anthropic", "openai-codex"] as const;
const CHAT_KINDS: Readonly<Record<string, true>> = { chat: true, tiny: true };

interface Token {
	access: string;
	login?: string;
}

interface Entry {
	name: string;
	kind: string;
}

async function crestAuth(...args: string[]): Promise<string> {
	const child = Bun.spawn(["crest-auth", "json", ...args], { stdout: "pipe", stderr: "pipe" });
	const [stdout, stderr, code] = await Promise.all([
		new Response(child.stdout).text(),
		new Response(child.stderr).text(),
		child.exited,
	]);
	if (code !== 0) throw new Error(`crest-auth json ${args.join(" ")}: ${stderr.trim()}`);
	return stdout;
}

async function token(provider: string): Promise<Token> {
	const value: unknown = JSON.parse(await crestAuth("token", provider));
	if (typeof value !== "object" || value === null || !("access" in value) || typeof value.access !== "string") {
		throw new Error(`crest-auth json token ${provider}: no access token`);
	}
	const login = "login" in value && typeof value.login === "string" ? value.login : undefined;
	return { access: value.access, login };
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

function rotating(provider: string): ApiKeyResolver {
	const logins = new Map<string, string>();
	return async ({ error, lastChance, previousKey }) => {
		const spent = previousKey === undefined ? undefined : logins.get(previousKey);
		if (error !== undefined && lastChance && spent !== undefined) await crestAuth("cool", spent);
		const next = await token(provider);
		if (next.login !== undefined) logins.set(next.access, next.login);
		return next.access;
	};
}

export default async function crest(pi: ExtensionAPI): Promise<void> {
	const providers = await signedIn();
	for (const provider of PROVIDERS) {
		const bundled = getBundledModels(provider);
		const baseUrl = bundled[0]?.baseUrl;
		if (!providers.has(provider) || baseUrl === undefined) continue;
		const api = `crest-${provider}`;
		const wire = new Map(bundled.map((model) => [model.id, model]));
		pi.registerProvider(provider, {
			baseUrl,
			apiKey: `!crest-auth json token ${provider} | jq -r .access`,
			api,
			models: bundled.map((model) => (Object.hasOwn(CHAT_KINDS, model.kind ?? "chat") ? { ...model, api } : model)),
			streamSimple(model, context, options) {
				const target = wire.get(model.id);
				if (target === undefined) throw new Error(`crest: ${provider} has no bundled model ${model.id}`);
				return streamSimple(target, context, { ...options, apiKey: rotating(provider) });
			},
		});
	}
}
