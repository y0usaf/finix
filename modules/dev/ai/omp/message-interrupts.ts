// Messages that reach a bot from anyone but the user: helper reports merging back and peer/other-bot
// messages. Off by default, they must not change a running turn: held out of every provider request
// until the run ends, then released together with a single wake. On, they behave exactly as omp
// delivers them today (a mid-turn peer/helper message folds in at the step boundary).
//
// omp owns delivery, so nothing here re-sends a report: the message stays in the transcript and in the
// session's context, and the `context` hook only drops it from the request payload while a run that
// did not start from it is live. At the end of that run the hold is released, so the same report sits
// in context for the one wake that follows.
//
// A run started by such a message is a wake: its first model call waits a few seconds and anything
// arriving in that window folds into the same run instead of being held, so two reports arriving
// while idle cost one wake. A failed helper report never waits.
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

/** Identity of a non-user message addressed to this session, or undefined for anything else. */
function inbound(message: Message): { key: string; failed: boolean; kind: string } | undefined {
	if (message.role !== "custom") return undefined;
	const details = record(message.details) ? message.details : undefined;
	if (details === undefined) return undefined;
	const stamp = message.timestamp ?? 0;
	if (message.customType === "async-result") {
		const jobs = Array.isArray(details.jobs) ? details.jobs.filter(record) : [];
		// Background bash/eval completions are work this session started itself; only a helper
		// (task) report is a message from someone else.
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
	// A run is one user-visible turn: `turn_end` fires per model step, so the hold lives until the run.
	let run = { fresh: true, baseline: new Set<string>(), held: new Set<string>(), foldNext: false };

	const main = (ctx: ExtensionContext) => ctx.agent.kind === "main";

	const wake = (count: number) => {
		// The reports themselves are already in context; this only starts the turn that reads them.
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
			// A run whose first request ends on a message from a helper or peer was woken by it:
			// wait out the batch window so anything else arriving lands in this same run.
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
			// omp queues a report that lands during the wait and only commits it once this model
			// call runs, so the request after the wait is where those arrivals show up: fold them
			// into this run instead of holding them for a wake of their own.
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
				// Arrived while the wake waited out the batch window: fold it into this run.
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
		// Auto-continuations settle later; only the terminal settle ends the turn the user sees.
		if (event.willContinue === true) return;
		const count = run.held.size;
		run = { fresh: true, baseline: new Set<string>(), held: new Set<string>(), foldNext: false };
		if (count === 0) return;
		// The user stopped this run: like omp's own background deliveries, the report joins the
		// next deliberate turn instead of restarting what they stopped.
		const last = [...event.messages].reverse().find(message => message.role === "assistant");
		if (last?.role === "assistant" && last.stopReason === "aborted") {
			return;
		}
		wake(count);
	});
}
