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
	ast_edit: true,
	edit: true,
	web_crawl: true,
};

const GOLDFISH_ALLOW: Record<string, true> = {
	read: true,
	grep: true,
	find: true,
};

const EVAL_TOP_LEVEL: Record<string, true> = {
	eval: true,
	yield: true,
};

async function prune(pi: ExtensionAPI, ctx?: ExtensionContext): Promise<void> {
	const isGoldfish = ctx?.agent?.name === "goldfish";
	const active = pi.getActiveTools();
	const kept = isGoldfish
		? active.filter(name => name in GOLDFISH_ALLOW)
		: active.includes("eval")
			? active.filter(name => name in EVAL_TOP_LEVEL)
			: active.filter(name => !(name in OFF));
	if (kept.length !== active.length) await pi.setActiveTools(kept);
}

export default function tools(pi: ExtensionAPI): void {
	pi.on("session_start", (_event, ctx) => prune(pi, ctx));
	pi.on("before_agent_start", (_event, ctx) => prune(pi, ctx));
}
