import type { ExtensionAPI, ExtensionContext } from "@oh-my-pi/pi-coding-agent";

const OFF: Record<string, true> = {
	read: true,
	grep: true,
	glob: true,
	find: true,
	wait: true,
	todo: true,
	web_fetch: true,
	lsp: true,
	box: true,
	context_check: true,
	date: true,
	recent: true,
	memories: true,
	ast_edit: true,
	edit: true,
	web_crawl: true,
};

const GOLDFISH_ALLOW: Record<string, true> = {
	read: true,
	grep: true,
	glob: true,
	find: true,
};

const GOLDFISH_DENY: Record<string, true> = {
	bash: true,
	write: true,
	edit: true,
	ast_edit: true,
	task: true,
	goldfish: true,
};

async function prune(pi: ExtensionAPI, ctx?: ExtensionContext): Promise<void> {
	const isGoldfish = ctx?.agent?.name === "goldfish";
	const active = pi.getActiveTools();
	const kept = isGoldfish
		? active.filter(name => !(name in GOLDFISH_DENY) && (name in GOLDFISH_ALLOW || !(name in OFF)))
		: active.filter(name => !(name in OFF));
	if (kept.length !== active.length) await pi.setActiveTools(kept);
}

export default function tools(pi: ExtensionAPI): void {
	pi.on("session_start", (_event, ctx) => prune(pi, ctx));
	pi.on("before_agent_start", (_event, ctx) => prune(pi, ctx));
}
