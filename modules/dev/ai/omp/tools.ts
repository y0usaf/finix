import type { ExtensionAPI, ExtensionContext } from "@oh-my-pi/pi-coding-agent";

const GOLDFISH_ALLOW: Record<string, true> = {
	read: true,
	grep: true,
	find: true,
};

async function prune(pi: ExtensionAPI, ctx?: ExtensionContext): Promise<void> {
	const isGoldfish = ctx?.agent?.name === "goldfish";
	const active = pi.getActiveTools();
	const kept = isGoldfish
		? active.filter(name => name in GOLDFISH_ALLOW)
		: active.filter(name => name === "bash");
	if (kept.length !== active.length) await pi.setActiveTools(kept);
}

export default function tools(pi: ExtensionAPI): void {
	pi.on("session_start", (_event, ctx) => prune(pi, ctx));
	pi.on("before_agent_start", (_event, ctx) => prune(pi, ctx));
}
