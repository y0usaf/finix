import type { ExtensionAPI, ExtensionContext } from "@oh-my-pi/pi-coding-agent";
import * as fs from "node:fs";
import * as path from "node:path";
import {
	type Entry,
	LOG,
	MAIN,
	Messages,
	PLACEHOLDER,
	TREE,
	Tail,
	bytes,
	flat,
	key,
	line,
	readState,
	readView,
	when,
} from "./store.ts";

const PIN = "optchat-pin";
const CAP = 30_000;
const RECENT = 64_000;
const ROW = /^(\d+)\+(\d+)\|/;

const INTRO = `# Shared memory

Every omp chat on this computer, on the host and in the box, logs the
user's messages and the agent's replies into one shared memory. Below is
its view, taken when this chat started or was last compacted: everything
logged before then, oldest first, inside <chat> tags, as one-line
summaries. Each line is

  id+n|text   the n messages from id on, summarized (newlines shown as spaces)

Each item is tagged with its kind and, in brackets, the chat it came from,
as talk[Chat]: user (the user's words in that chat), work (text an agent
or tool sent in the user's place), talk (the agent's replies). Tool calls
and their results are not logged, so say in your replies what you learned
that will matter later. Recent lines cover one message each; the older
the messages, the more a line covers. A message not summarized yet shows
as "${PLACEHOLDER}". Read other chats' lines as what else is
going on and answer only this chat's messages; this chat's own turns
follow in full, or as omp's summary once it has compacted them.

The zoom, date and recent tools read the memory. zoom(id, n) opens line
id+n into the two lines of n/2 messages it was made from; zoom(id, 1)
gives message id in full. Zoom whenever a summary only mentions something
you need, such as a decision, a past attempt or where a file is, before
you act, guess or ask. date(id) gives the date and time of message id.
recent() shows what every chat logged after this view was taken.`;

interface Pin {
	view: string;
	upto: number;
	time: number;
}

interface Block {
	type: string;
	text?: string;
}

interface Logged {
	role: string;
	content?: unknown;
	attribution?: string;
	stopReason?: string;
	timestamp?: number;
}

function joinText(content: unknown): string {
	if (typeof content === "string") return content;
	if (!Array.isArray(content)) return "";
	return content
		.map((block: Block) => (block?.type === "text" ? (block.text ?? "") : block?.type === "image" ? "[image]" : ""))
		.filter(Boolean)
		.join("\n");
}

function capText(text: string): string {
	const chars = [...text];
	if (chars.length <= CAP) return text;
	const half = CAP / 2;
	return `${chars.slice(0, half).join("")}\n\n[${chars.length - CAP} characters cut]\n\n${chars.slice(chars.length - half).join("")}`;
}

function entriesOf(message: Logged): { kind: string; text: string }[] {
	if (message.role === "user") {
		const text = joinText(message.content).trim();
		return text ? [{ kind: message.attribution === "agent" ? "work" : "user", text }] : [];
	}
	if (message.role === "assistant" && message.stopReason !== "error" && message.stopReason !== "aborted") {
		const content = Array.isArray(message.content) ? (message.content as Block[]) : [];
		const text = content
			.filter((block) => block.type === "text")
			.map((block) => block.text ?? "")
			.join("\n\n")
			.trim();
		return text ? [{ kind: "talk", text }] : [];
	}
	return [];
}

function chatName(title: string | undefined, session: string): string {
	const plain = (title ?? "").replace(/[^\x20-\x7e]/g, "").trim();
	const code = /^([A-Z0-9][A-Z0-9_-]{1,11}):\s/.exec(plain)?.[1];
	if (code) return code;
	if (plain) return plain.slice(0, 32).trimEnd();
	return `chat ${session.slice(-6)}`;
}

function pins(ctx: ExtensionContext): Pin[] {
	return ctx.sessionManager
		.getBranch()
		.filter((entry) => entry.type === "custom" && entry.customType === PIN)
		.map((entry) => (entry as { data?: Pin }).data)
		.filter((pin): pin is Pin => typeof pin?.view === "string" && typeof pin.upto === "number");
}

function take(): Pin {
	return { view: readView(), upto: readState()?.messages ?? 0, time: Date.now() };
}

function recent(since: number): string {
	const rows = readView()
		.split("\n")
		.filter((row) => {
			const match = ROW.exec(row);
			return match !== null && Number(match[1]) + Number(match[2]) > since;
		});
	if (!rows.length) return "Nothing was logged after this chat's view was taken.";
	const kept: string[] = [];
	let size = 0;
	for (let k = rows.length - 1; k >= 0 && size < RECENT; k--) {
		kept.unshift(rows[k]);
		size += bytes(rows[k]) + 1;
	}
	return `<chat>\n${kept.join("\n")}\n</chat>`;
}

export default function optchat(pi: ExtensionAPI): void {
	const z = pi.zod;
	const messages = new Messages();
	const tree = new Tail(TREE);
	const nodes = new Map<string, string>();
	let enabled = false;

	const active = (ctx: ExtensionContext) => enabled && ctx.agent?.kind === "main";
	const result = (text: string) => ({ content: [{ type: "text" as const, text }] });

	function node(l: number, i: number): string | undefined {
		for (const row of tree.read()) {
			if (!row) continue;
			try {
				const parsed = JSON.parse(row) as { l: number; i: number; text: string };
				nodes.set(key(parsed.l, parsed.i), parsed.text);
			} catch {}
		}
		return nodes.get(key(l, i));
	}

	function zoom(id: number, n: number): string {
		const total = readState()?.messages ?? 0;
		if (
			!Number.isSafeInteger(id) ||
			!Number.isSafeInteger(n) ||
			n < 1 ||
			n > 2 ** 30 ||
			(n & (n - 1)) !== 0 ||
			id < 0 ||
			id % n !== 0 ||
			id + n > total
		) {
			return `No line ${id}+${n}.`;
		}
		if (n === 1) {
			const message = messages.get(id);
			return message ? `${id}+1|${line(message)}` : `No message ${id}.`;
		}
		const half = n / 2;
		const l = Math.log2(half);
		return [id, id + half].map((at) => `${at}+${half}|${flat(node(l, at / half) ?? PLACEHOLDER)}`).join("\n");
	}

	pi.registerTool({
		name: "zoom",
		label: "Zoom memory",
		description:
			"Open the line id+n of the shared memory view into the two lines of n/2 messages under it; n = 1 gives message id whole.",
		parameters: z.object({ id: z.number(), n: z.number() }),
		async execute(_toolCallId, params) {
			return result(zoom(params.id, params.n));
		},
	});
	pi.registerTool({
		name: "date",
		label: "Memory date",
		description: "The date and time of shared memory message id.",
		parameters: z.object({ id: z.number() }),
		async execute(_toolCallId, params) {
			const message = messages.get(params.id);
			return result(message ? when(message.time) : `No message ${params.id}.`);
		},
	});
	pi.registerTool({
		name: "recent",
		label: "Recent memory",
		description: "The shared memory lines every chat logged after this chat's view was taken.",
		parameters: z.object({}),
		async execute(_toolCallId, _params, _signal, _onUpdate, ctx) {
			return result(recent(pins(ctx).at(-1)?.upto ?? 0));
		},
	});

	function start(ctx: ExtensionContext): void {
		enabled =
			ctx.agent?.kind === "main" &&
			(ctx.mode === "tui" || ctx.mode === "rpc") &&
			ctx.sessionManager.getSessionFile() !== undefined &&
			fs.existsSync(MAIN);
	}

	pi.on("session_start", async (_event, ctx) => start(ctx));
	pi.on("session_switch", async (_event, ctx) => start(ctx));

	pi.on("message_end", async (event, ctx) => {
		if (!active(ctx)) return;
		const message = event.message as Logged;
		const session = ctx.sessionManager.getSessionId();
		const name = chatName(pi.getSessionName(), session);
		const time = typeof message.timestamp === "number" ? message.timestamp : Date.now();
		const rows = entriesOf(message).map(
			({ kind, text }) => `${JSON.stringify({ kind, text: capText(text), time, name } satisfies Entry)}\n`,
		);
		if (rows.length) fs.appendFileSync(path.join(LOG, `${session}.jsonl`), rows.join(""));
	});

	pi.on("context", async (event, ctx) => {
		if (!active(ctx)) return undefined;
		let pin = pins(ctx).at(-1);
		if (pin === undefined) {
			pin = take();
			pi.appendEntry(PIN, pin);
		}
		const block = { type: "text" as const, text: `${INTRO}\n\n${pin.view}` };
		const at = event.messages.findIndex((message) => message.role === "user");
		if (at < 0) return { messages: [{ role: "user", content: [block], timestamp: pin.time }, ...event.messages] };
		const first = event.messages[at] as Extract<(typeof event.messages)[number], { role: "user" }>;
		const content = typeof first.content === "string" ? [{ type: "text" as const, text: first.content }] : first.content;
		return { messages: event.messages.with(at, { ...first, content: [block, ...content] }) };
	});

	pi.on("session_compact", async (_event, ctx) => {
		if (active(ctx)) pi.appendEntry(PIN, take());
	});
}
