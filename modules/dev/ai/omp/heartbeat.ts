import type { ExtensionAPI, ExtensionContext } from "@oh-my-pi/pi-coding-agent";
import { existsSync, readFileSync, renameSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

type HeartbeatPacket = {
	seq: number;
	ts?: string;
	trigger?: string;
	urgent?: boolean;
	digest?: unknown;
};

function parsePacket(value: unknown): HeartbeatPacket | undefined {
	if (typeof value !== "object" || value === null || Array.isArray(value)) return undefined;
	if (!("seq" in value) || typeof value.seq !== "number" || !Number.isFinite(value.seq)) return undefined;
	return {
		seq: value.seq,
		ts: "ts" in value && typeof value.ts === "string" ? value.ts : undefined,
		trigger: "trigger" in value && typeof value.trigger === "string" ? value.trigger : undefined,
		urgent: "urgent" in value && typeof value.urgent === "boolean" ? value.urgent : undefined,
		digest: "digest" in value ? value.digest : undefined,
	};
}

class HeartbeatCard {
	title: string;
	body: string;

	constructor(message: { details?: unknown }) {
		const pkt = parsePacket(message.details);
		const trigger = pkt?.trigger || "SCHEDULED";
		const seq = pkt !== undefined ? ` #${pkt.seq}` : "";
		const urgent = pkt?.urgent ? " [URGENT]" : "";
		this.title = `Heartbeat · ${trigger}${seq}${urgent}`;
		const ts = pkt?.ts ? `**Time:** ${pkt.ts}` : "";
		this.body = [ts, "```json", JSON.stringify(pkt?.digest ?? {}, null, 2), "```"].filter(Boolean).join("\n");
	}

	invalidate() {}

	describe() {
		return {
			k: "card",
			p: { role: "omp.custom", variant: "bare", head: [{ t: this.title, s: "muted" }] },
			c: [{ k: "md", p: { text: this.body } }],
		};
	}

	render() {
		return [this.title, ...this.body.split("\n")];
	}
}

function readPacket(path: string): HeartbeatPacket | undefined {
	try {
		return parsePacket(JSON.parse(readFileSync(path, "utf8")));
	} catch {}
	return undefined;
}

function readLastSeq(path: string): number {
	try {
		const n = Number(readFileSync(path, "utf8").trim());
		return Number.isFinite(n) && n >= 0 ? n : 0;
	} catch {
		return 0;
	}
}

function writeAtomic(path: string, content: string): void {
	const tmp = `${path}.tmp.${process.pid}`;
	writeFileSync(tmp, content, { mode: 0o600 });
	renameSync(tmp, path);
}

function formatPacket(pkt: HeartbeatPacket): string {
	const trigger = pkt.trigger ?? "SCHEDULED";
	const ts = pkt.ts ?? new Date().toISOString();
	const urgent = pkt.urgent ? ' urgent="true"' : "";
	return [
		`<heartbeat seq="${pkt.seq}" trigger="${trigger}" ts="${ts}"${urgent}>`,
		"Deterministic digest from host mint-execd. Assess regime, verify against policy invariants, and reply concisely (4-5 lines for HOLD).",
		"",
		"```json",
		JSON.stringify(pkt.digest ?? {}, null, 2),
		"```",
		"</heartbeat>",
	].join("\n");
}

export default function heartbeat(pi: ExtensionAPI): void {
	const name = process.env.OMP_BOT_NAME;
	if (!name) return;
	pi.setLabel("Heartbeat");
	const state =
		process.env.OMP_BOT_STATE || join(process.env.XDG_STATE_HOME || join(homedir(), ".local", "state"), "omp-bot");
	const dir = join(state, "bots", name, "heartbeat");
	const latestPath = join(dir, "latest.json");
	const seqPath = join(dir, "last_seq");
	const alivePath = join(dir, "alive");

	pi.registerMessageRenderer("heartbeat", message => new HeartbeatCard(message));

	pi.on("session_start", (_event, ctx: ExtensionContext) => {
		if (ctx.agent?.kind !== "main") return;
		const tick = () => {
			if (!existsSync(dir)) return;
			try {
				writeFileSync(alivePath, `${Date.now()}\n`, { mode: 0o600 });
			} catch {}
			if (!ctx.isIdle() || ctx.hasPendingMessages()) return;
			const pkt = readPacket(latestPath);
			if (!pkt) return;
			const lastSeq = readLastSeq(seqPath);
			if (pkt.seq <= lastSeq) return;
			try {
				writeAtomic(seqPath, `${pkt.seq}\n`);
			} catch {
				return;
			}
			pi.sendMessage(
				{
					customType: "heartbeat",
					content: formatPacket(pkt),
					display: true,
					attribution: "agent",
					details: pkt,
				},
				{ triggerTurn: true },
			);
		};
		ctx.setTimeout(() => ctx.setInterval(tick, 5000), 5000);
	});
}
