import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

function isStringArray(value: unknown): value is string[] {
	return Array.isArray(value) && value.every((entry) => typeof entry === "string");
}

export default function (pi: ExtensionAPI) {
	function readChain(): string[] {
		const settings = pi.getSettings();
		if ("fallbackModels" in settings && isStringArray(settings.fallbackModels) && settings.fallbackModels.length > 0) {
			return settings.fallbackModels;
		}
		throw new Error('settings.json needs "fallbackModels": a non-empty array of "provider/model" strings');
	}

	pi.registerVirtualModel({
		provider: "fallback",
		id: "chain",
		name: "Fallback chain",
		thinkingLevels: ["off", "minimal", "low", "medium", "high", "xhigh", "max"],
		route({ reason, previous, failed, thinkingLevel }, ctx) {
			if (reason === "continuation" && previous) return { model: previous.model, thinkingLevel };
			const chain = readChain();
			const failedAt = reason === "retry" && failed ? chain.indexOf(`${failed.model.provider}/${failed.model.id}`) : -1;
			for (const entry of chain.slice(failedAt + 1)) {
				const slash = entry.indexOf("/");
				const model = ctx.modelRegistry.find(entry.slice(0, slash), entry.slice(slash + 1));
				if (model && ctx.modelRegistry.hasConfiguredAuth(model)) return { model, thinkingLevel };
			}
			if (failed) return { model: failed.model, thinkingLevel };
			throw new Error(`no usable model in fallbackModels: ${chain.join(", ")}`);
		},
	});
}
