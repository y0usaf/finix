import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

const USAGE = "Usage: /system <text> | /system append <text> | /system edit | /system clear | /system reset";

export default function ablitSystemExtension(pi: ExtensionAPI) {
	pi.setLabel("System prompt");

	const bareMode = process.env.OMP_ABLIT_BARE === "1";
	const initialBarePrompt = bareMode ? (process.env.OMP_ABLIT_SYSTEM_PROMPT ?? "") : "";
	let override: string | null = bareMode ? initialBarePrompt : null;
	let appended: string[] = [];

	pi.on("before_agent_start", (event) => {
		if (override !== null) {
			return {
				systemPrompt: override.length > 0 ? [override] : [],
			};
		}
		if (appended.length > 0) {
			return {
				systemPrompt: [...event.systemPrompt, ...appended],
			};
		}
		return undefined;
	});

	const handleSystemCommand = async (
		args: string,
		ctx: Parameters<Parameters<ExtensionAPI["registerCommand"]>[1]["handler"]>[1],
	) => {
		const raw = String(args ?? "");
		const trimmed = raw.trim();

		if (!trimmed) {
			let display: string;
			if (override !== null) {
				display = override.length > 0 ? override : "(empty)";
			} else if (appended.length > 0) {
				display = `(default)\n\n[appended]\n${appended.join("\n\n")}`;
			} else {
				display = "(default)";
			}
			ctx.ui.notify(`System prompt:\n${display}\n\n${USAGE}`, "info");
			return;
		}

		const lower = trimmed.toLowerCase();
		if (lower === "clear" || lower === "off" || lower === "none") {
			override = "";
			appended = [];
			ctx.ui.notify("System prompt cleared.", "info");
			return;
		}

		if (lower === "reset" || lower === "default") {
			override = bareMode ? initialBarePrompt : null;
			appended = [];
			ctx.ui.notify(bareMode ? "System prompt reset to initial value." : "System prompt reset to default.", "info");
			return;
		}

		if (lower === "edit") {
			const seed = override !== null ? override : appended.join("\n\n");
			const edited = await ctx.ui.editor("System prompt", seed);
			if (edited === undefined) {
				ctx.ui.notify("System prompt unchanged.", "info");
				return;
			}
			override = edited.trim();
			appended = [];
			ctx.ui.notify(override.length > 0 ? "System prompt updated." : "System prompt cleared.", "info");
			return;
		}

		const appendMatch = /^append(?:\s+([\s\S]+))?$/i.exec(trimmed);
		if (appendMatch) {
			const addition = (appendMatch[1] ?? "").trim();
			if (!addition) {
				ctx.ui.notify(USAGE, "info");
				return;
			}
			if (override !== null) {
				override = override.length > 0 ? `${override}\n\n${addition}` : addition;
			} else {
				appended.push(addition);
			}
			ctx.ui.notify("System prompt updated.", "info");
			return;
		}

		override = trimmed;
		appended = [];
		ctx.ui.notify("System prompt updated.", "info");
	};

	pi.registerCommand("system", {
		description: "View or change the system prompt for this session",
		handler: handleSystemCommand,
	});

	pi.registerCommand("sys", {
		description: "Alias for /system",
		handler: handleSystemCommand,
	});
}
