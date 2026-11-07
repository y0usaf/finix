import { buildDirectoryArgumentCompletions } from "@oh-my-pi/pi-coding-agent/slash-commands/builtin-completions";

export default function cwd(pi) {
	pi.setLabel("Working directory");

	pi.on("input", async event => {
		const dir = /^\/cwd\s+(\S[\s\S]*)$/.exec(String(event.text ?? "").trim())?.[1];
		return dir ? { text: `/move ${dir}` } : undefined;
	});

	pi.registerCommand("cwd", {
		description: "Show the working directory; /cwd DIR moves the session there, as /move does",
		getArgumentCompletions: buildDirectoryArgumentCompletions(),
		handler: async (_args, ctx) => {
			ctx.ui.notify(ctx.sessionManager.getCwd(), "info");
		},
	});
}
