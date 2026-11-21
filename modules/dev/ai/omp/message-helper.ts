import type { ExtensionAPI, ExtensionContext } from "@oh-my-pi/pi-coding-agent";
import { IrcBus, type IrcBusApi } from "@oh-my-pi/pi-coding-agent/irc/bus";
import {
	type AgentRef,
	AgentRegistry,
	type AgentRegistryApi,
	isBlindAuditor,
} from "@oh-my-pi/pi-coding-agent/registry/agent-registry";

export interface HelperJob {
	id: string;
	type: string;
	status: string;
	agentId?: string;
}

export interface HelperJobs {
	running: HelperJob[];
	recent: HelperJob[];
}

export interface MessageHelperInput {
	senderId: string;
	to: string;
	message: string;
	jobs?: HelperJobs | null;
	registry?: AgentRegistryApi;
	bus?: IrcBusApi;
}

export interface MessageHelperResult {
	to: string;
	outcome: "queued" | "woken";
	text: string;
}

const SCHEMA = {
	type: "object",
	additionalProperties: false,
	required: ["to", "message"],
	properties: {
		to: { type: "string", description: "Helper name (agent id) or its task job id." },
		message: { type: "string", description: "Message body." },
	},
};

const DESCRIPTION =
	"Message one of your own running helpers (task subagents, by name or job id). It reads the message at its next step boundary (never mid-tool); an idle helper is woken. Goldfish auditors cannot be messaged.";

function ancestors(registry: AgentRegistryApi, id: string): string[] {
	const chain: string[] = [];
	const seen = new Set<string>([id]);
	for (let next = registry.get(id)?.parentId; next !== undefined && !seen.has(next); next = registry.get(next)?.parentId) {
		chain.push(next);
		seen.add(next);
	}
	return chain;
}

function finished(ref: AgentRef): boolean {
	return ref.status === "parked" || ref.status === "aborted" || ref.lifecycle?.acceptedAt !== undefined;
}

function liveHelpers(registry: AgentRegistryApi, senderId: string): string[] {
	return registry
		.list()
		.filter(
			ref =>
				ref.kind === "sub" &&
				!isBlindAuditor(ref) &&
				!finished(ref) &&
				ancestors(registry, ref.id).includes(senderId),
		)
		.map(ref => ref.id)
		.sort();
}

export async function messageHelper(input: MessageHelperInput): Promise<MessageHelperResult> {
	const registry = input.registry ?? AgentRegistry.global();
	const bus = input.bus ?? IrcBus.global();
	const senderId = input.senderId;
	const raw = String(input.to ?? "").trim().replace(/^agent:\/\//, "").replace(/\/+$/, "");
	const body = String(input.message ?? "");
	if (!raw) throw new Error("message_helper needs a helper name or job id in `to`.");
	if (!body.trim()) throw new Error("message_helper needs a non-empty `message`.");
	if (raw === "all") throw new Error("message_helper sends to one helper; `all` is not a helper.");

	const [running, recent] = [input.jobs?.running, input.jobs?.recent].map(list =>
		(list ?? []).filter(job => job.type === "task" && typeof job.agentId === "string" && job.agentId.length > 0),
	);
	const byJob = running.find(job => job.id === raw) ?? recent.find(job => job.id === raw);
	const id = byJob?.agentId ?? raw;
	if (id === senderId) throw new Error("message_helper cannot message yourself.");
	const liveJob = running.find(job => job.agentId === id);
	const doneJob = liveJob ? undefined : recent.find(job => job.agentId === id);
	const label = byJob && byJob.id !== id ? `${id} (job ${byJob.id})` : id;

	const ref = registry.get(id);
	if (ref && isBlindAuditor(ref)) {
		throw new Error(
			`Refused: ${label} is a Goldfish audit agent. Goldfish is blind and zero-history by design, so it can never be messaged; run a fresh audit instead.`,
		);
	}
	if (!ref) {
		if (doneJob) throw new Error(`Helper ${label} already finished (job ${doneJob.id}: ${doneJob.status}); there is no running helper to message.`);
		const live = liveHelpers(registry, senderId);
		throw new Error(
			`Unknown helper "${raw}". ${live.length > 0 ? `Your running helpers: ${live.join(", ")}.` : "You have no running helpers."}`,
		);
	}
	if (ref.kind !== "sub") throw new Error(`${label} is not a helper (it is a ${ref.kind} agent).`);
	if (!ancestors(registry, id).includes(senderId)) {
		throw new Error(
			`${label} is not one of your helpers (its parent is ${ref.parentId ?? "none"}); you can only message your own descendants.`,
		);
	}
	if (finished(ref)) {
		const how = ref.lifecycle?.acceptedAt !== undefined ? "result delivered" : ref.status;
		throw new Error(`Helper ${label} already finished (${how}); there is no running helper to message.`);
	}
	if (ref.session === null) throw new Error(`Helper ${label} is still starting; message it once it is running.`);

	const receipt = await bus.send({ from: senderId, to: id, body, aside: true });
	if (receipt.outcome === "failed") {
		throw new Error(`Could not deliver to ${label}: ${receipt.error ?? "delivery failed"}`);
	}
	const outcome = receipt.outcome === "woken" ? "woken" : "queued";
	return {
		to: id,
		outcome,
		text:
			outcome === "woken"
				? `Delivered to ${label}; it was between turns and has been woken to read it.`
				: `Queued for ${label}; it reads the message at its next step boundary.`,
	};
}

function jobsOf(ctx: ExtensionContext): HelperJobs | null {
	const snapshot = ctx.getAsyncJobSnapshot?.();
	if (!snapshot) return null;
	return { running: snapshot.running, recent: snapshot.recent };
}

export default function messageHelperExtension(pi: ExtensionAPI): void {
	pi.on("session_start", (_event, ctx) => {
		if (ctx.agent?.name === "goldfish") return;
		pi.registerTool({
			name: "message_helper",
			label: "Message helper",
			description: DESCRIPTION,
			parameters: SCHEMA,
			async execute(_toolCallId, params, _signal, _onUpdate, toolCtx) {
				const input = (params ?? {}) as { to?: unknown; message?: unknown };
				const senderId = toolCtx.agent?.id ?? ctx.agent?.id;
				if (!senderId) throw new Error("message_helper has no agent identity in this session.");
				const result = await messageHelper({
					senderId,
					to: String(input.to ?? ""),
					message: String(input.message ?? ""),
					jobs: jobsOf(toolCtx),
				});
				return { content: [{ type: "text", text: result.text }], details: result };
			},
		});
	});
}
