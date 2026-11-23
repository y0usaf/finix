import type {
	AgentEndEvent,
	AgentStartEvent,
	ContextEvent,
	ExtensionAPI,
	ExtensionContext,
} from "@oh-my-pi/pi-coding-agent";

type Message = ContextEvent["messages"][number];

const BATCH_MS = 3_000;
const WAKE = "message-interrupts";
const FAILED_TASK = /<task-result\b[^>]*\bstatus="(?:failed|aborted|killed)"/;

function record(value: unknown): value is Record<string, unknown> {
	return typeof value === "object" && value !== null;
}

function textOf(message: Message): string {
	const content = "content" in message ? message.content : undefined;
	if (typeof content === "string") return content;
	if (!Array.isArray(content)) return "";
	return content
		.map(part => (record(part) && part.type === "text" && typeof part.text === "string" ? part.text : ""))
		.join("\n");
}

function inbound(message: Message): { key: string; failed: boolean; kind: string } | undefined {
	if (message.role !== "custom") return undefined;
	const details = record(message.details) ? message.details : undefined;
	if (details === undefined) return undefined;
	const stamp = message.timestamp ?? 0;
	if (message.customType === "async-result") {
		const jobs = Array.isArray(details.jobs) ? details.jobs.filter(record) : [];
		if (!jobs.some(job => job.type === "task")) return undefined;
		const ids = jobs.map(job => String(job.jobId ?? "?")).join(",");
		const failed =
			jobs.some(job => job.status !== undefined && job.status !== "completed") ||
			FAILED_TASK.test(textOf(message));
		return { key: `async:${ids}:${stamp}`, failed, kind: "helper" };
	}
	if (message.customType === "irc:incoming") {
		return { key: `irc:${String(details.id ?? "")}:${stamp}`, failed: false, kind: "peer" };
	}
	return undefined;
}

export default function messageInterrupts(pi: ExtensionAPI) {
	let run = { fresh: true, baseline: new Set<string>(), held: new Set<string>(), foldNext: false };

	const main = (ctx: ExtensionContext) => ctx.agent.kind === "main";

	const wake = (count: number) => {
		try {
			pi.sendMessage(
				{
					customType: WAKE,
					content: "Message(s) from helpers or peers arrived during your turn. They are above; act on what needs doing.",
					display: false,
					attribution: "agent",
				},
				{ deliverAs: "nextTurn", triggerTurn: true },
			);
		} catch {}
	};

	pi.on("agent_start", (_event: AgentStartEvent, ctx) => {
		if (!main(ctx)) return;
		run = { fresh: true, baseline: new Set<string>(), held: new Set<string>(), foldNext: false };
	});

	pi.on("context", async (event, ctx) => {
		if (!main(ctx)) return undefined;
		const messages = event.messages;
		const last = messages[messages.length - 1];
		if (run.fresh) {
			run.fresh = false;
			const trigger = last === undefined ? undefined : inbound(last);
			for (const message of messages) {
				const info = inbound(message);
				if (info !== undefined) run.baseline.add(info.key);
			}
			if (trigger === undefined) return undefined;
			if (trigger.failed) {
				return undefined;
			}
			await Bun.sleep(BATCH_MS);
			run.foldNext = true;
			return undefined;
		}
		const kept: Message[] = [];
		const fold = run.foldNext;
		run.foldNext = false;
		let dropped = 0;
		for (const message of messages) {
			const info = inbound(message);
			if (info === undefined || info.failed) {
				kept.push(message);
				continue;
			}
			if (run.baseline.has(info.key)) {
				kept.push(message);
				continue;
			}
			if (fold) {
				run.baseline.add(info.key);
				kept.push(message);
				continue;
			}
			if (!run.held.has(info.key)) {
				run.held.add(info.key);
			}
			dropped++;
		}
		return dropped === 0 ? undefined : { messages: kept };
	});

	pi.on("agent_end", async (event: AgentEndEvent, ctx) => {
		if (!main(ctx)) return;
		if (event.willContinue === true) return;
		const count = run.held.size;
		run = { fresh: true, baseline: new Set<string>(), held: new Set<string>(), foldNext: false };
		if (count === 0) return;
		const last = [...event.messages].reverse().find(message => message.role === "assistant");
		if (last?.role === "assistant" && last.stopReason === "aborted") {
			return;
		}
		wake(count);
	});
}
