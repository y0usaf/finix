import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

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

async function prune(pi: ExtensionAPI): Promise<void> {
	const active = pi.getActiveTools();
	const kept = active.filter(name => !(name in OFF));
	if (kept.length !== active.length) await pi.setActiveTools(kept);
}

export default function tools(pi: ExtensionAPI): void {
	pi.on("session_start", () => prune(pi));
	pi.on("before_agent_start", () => prune(pi));
}
