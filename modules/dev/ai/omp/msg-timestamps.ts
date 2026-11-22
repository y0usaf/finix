import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

const STAMP_RE = /^\[\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}\[[^\]]+\]\]/;

const formatter = new Intl.DateTimeFormat("en-US", {
	year: "numeric",
	month: "2-digit",
	day: "2-digit",
	hour: "2-digit",
	minute: "2-digit",
	second: "2-digit",
	hourCycle: "h23",
	timeZoneName: "longOffset",
});

const timeZone = formatter.resolvedOptions().timeZone;

function formatTimestamp(ms: unknown): string | undefined {
	if (typeof ms !== "number" || !Number.isFinite(ms) || ms <= 0 || ms > 8.64e15) return undefined;
	const parts = Object.fromEntries(formatter.formatToParts(ms).map((part) => [part.type, part.value]));
	const offset = (parts.timeZoneName ?? "GMT").replace(/^GMT$/, "GMT+00:00").slice(3);
	return `[${parts.year}-${parts.month}-${parts.day}T${parts.hour}:${parts.minute}:${parts.second}${offset}[${timeZone}]]`;
}

function prefixContent(content: unknown, stamp: string): unknown {
	if (typeof content === "string") {
		return STAMP_RE.test(content) ? content : `${stamp} ${content}`;
	}
	if (!Array.isArray(content)) return content;
	const idx = content.findIndex(
		(b) => b && typeof b === "object" && "type" in b && b.type === "text" && "text" in b && typeof b.text === "string",
	);
	if (idx < 0) return content;
	const block = content[idx];
	if (!block || typeof block !== "object" || !("text" in block) || typeof block.text !== "string") return content;
	if (STAMP_RE.test(block.text)) return content;
	return content.with(idx, { ...block, text: `${stamp} ${block.text}` });
}

export default function msgTimestamps(pi: ExtensionAPI): void {
	pi.on("context", async (event) => {
		const messages = event.messages.map((msg) => {
			if (msg.role !== "user" && msg.role !== "toolResult") return msg;
			const stamp = formatTimestamp("timestamp" in msg ? msg.timestamp : undefined);
			if (!stamp || !("content" in msg)) return msg;
			const nextContent = prefixContent(msg.content, stamp);
			if (nextContent === msg.content) return msg;
			return { ...msg, content: nextContent };
		});
		return { messages: messages as typeof event.messages };
	});
}
