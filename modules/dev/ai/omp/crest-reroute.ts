const GATEWAY = "vercel-ai-gateway";

function crest(name) {
	if (name.startsWith("anthropic/")) return `anthropic/${name.slice("anthropic/".length).replaceAll(".", "-")}`;
	if (name.startsWith("openai/")) return `openai-codex/${name.slice("openai/".length)}`;
	return undefined;
}

export default function crestReroute(pi) {
	const reroute = async (_event, ctx) => {
		const current = ctx.models.current();
		if (current?.provider !== GATEWAY) return;
		const name = crest(current.id);
		if (name === undefined) return;
		const routed = ctx.models.resolve(name);
		if (routed === undefined || routed.provider === GATEWAY) return;
		await pi.setModel(routed);
	};
	pi.on("session_start", reroute);
	pi.on("before_agent_start", reroute);
}
