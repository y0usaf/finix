import type { ExtensionAPI, ExtensionContext } from "@oh-my-pi/pi-coding-agent";
import * as fs from "node:fs";
import * as path from "node:path";
import {
	type Entry,
	Messages,
	PLACEHOLDER,
	STORE,
	type Store,
	Tail,
	bytes,
	flat,
	key,
	line,
	open,
	readState,
	readView,
	when,
} from "./store.ts";

const PIN = "optchat-pin";
const CAP = 30_000;
const RECENT = 64_000;
const ROW = /^(\d+)\+(\d+)\|/;
const COMPLETED = /<task-result id="([^"]+)"[^>]*status="completed"[^>]*>/g;
const BOT = process.env.OPTCHAT_BOT;
const RULES = process.env.OPTCHAT_RULES;
const BOTS = process.env.OPTCHAT_BOTS;
const RAW = Number(process.env.OPTCHAT_RAW) || 128_000;
const IMAGE = 4_800;

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

const BOT_INTRO = `# Your memory

Your conversation lives in OptChat memory, not in this context. Every
message you receive (the user typing live, background tasks, answers
from other bots) and every reply you write is logged into it. Below is
its view: everything logged before your latest turns, oldest first,
inside <chat> tags, as one-line summaries. Each line is

  id+n|text   the n messages from id on, summarized (newlines shown as spaces)

Each item is tagged with its kind: user (what you received), work (text
a tool sent in the user's place), talk (your replies). Recent lines
cover one message each; the older the messages, the more a line covers.
A message not summarized yet shows as "${PLACEHOLDER}". Your latest
turns follow in full, tool calls and results included; older turns exist
only as these lines, and their tool calls and results are gone, so say in
your replies what you learned that will matter later.

The zoom, date and recent tools read the memory. zoom(id, n) opens line
id+n into the two lines of n/2 messages it was made from; zoom(id, 1)
gives message id in full. Zoom whenever a summary only mentions something
you need, such as a decision, a past attempt or where a file is, before
you act, guess or ask. date(id) gives the date and time of message id.
recent() shows what was logged after this view was taken. Give any of
them a bot name to read that bot's memory instead, read-only; memories()
lists the bots that keep one.`;

const RULES_INTRO = `# Standing rules

The rules the user set you, kept word for word and never summarized.
They hold until the user changes them. When the user sets you a new
standing rule, pin_rule adds it here.`;

const HELPER_INTRO = `# Memory

An omp chat launched you as a helper. Below is the view of OptChat
memory that chat held when it launched you: everything logged before the
view was taken, oldest first, inside <chat> tags, as one-line summaries.
That chat's own latest turns are not in it. Each line is

  id+n|text   the n messages from id on, summarized (newlines shown as spaces)

Each item is tagged with its kind and, in brackets, the chat it came from,
as talk[Chat]: user (the user's words), work (text an agent, tool or
helper sent in the user's place), talk (the agent's replies). Recent lines
cover one message each; the older the messages, the more a line covers.
A message not summarized yet shows as "${PLACEHOLDER}". The view is
background for the task you were given, not a request.

The zoom, date and recent tools read the memory. zoom(id, n) opens line
id+n into the two lines of n/2 messages it was made from; zoom(id, 1)
gives message id in full. date(id) gives the date and time of message id.
recent() shows what was logged after this view was taken.`;

const LIFECYCLE = "task:subagent:lifecycle";
const RESULT = 2_000;
const PRIME = 20_000;
const leads = new Map<string, Promise<void>>();
const views = new Map<string, Pin>();

interface Pin {
	view: string;
	upto: number;
	time: number;
}

interface Snapshot extends Pin {
	anchor: number;
	turn: number;
}

interface Block {
	type: string;
	text?: string;
	name?: string;
	arguments?: unknown;
}

interface Run {
	id: string;
	description?: string;
	status: string;
	sessionFile?: string;
}

interface Logged {
	role: string;
	customType?: string;
	content?: unknown;
	attribution?: string;
	stopReason?: string;
	toolName?: string;
	details?: { question?: unknown };
	usage?: { totalTokens?: number };
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

function askText(message: Logged): string {
	if (message.role !== "toolResult" || message.toolName !== "ask") return "";
	const answer = joinText(message.content).trim();
	const question = message.details?.question;
	return answer && typeof question === "string" ? `Asked: ${question}\n${answer}` : answer;
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
	const answer = askText(message);
	return answer ? [{ kind: "user", text: answer }] : [];
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
	return { view: readView(STORE), upto: readState(STORE)?.messages ?? 0, time: Date.now() };
}

function recent(store: Store, since: number, empty: string): string {
	const rows = readView(store)
		.split("\n")
		.filter((row) => {
			const match = ROW.exec(row);
			return match !== null && Number(match[1]) + Number(match[2]) > since;
		});
	if (!rows.length) return empty;
	const kept: string[] = [];
	let size = 0;
	for (let k = rows.length - 1; k >= 0 && size < RECENT; k--) {
		kept.unshift(rows[k]);
		size += bytes(rows[k]) + 1;
	}
	return `<chat>\n${kept.join("\n")}\n</chat>`;
}

function said(message: Logged): string {
	const content = Array.isArray(message.content) ? (message.content as Block[]) : [];
	if (message.role === "assistant") {
		return `talk: ${content
			.map((block) => (block.type === "text" ? block.text : block.type === "toolCall" ? `${block.name} ${JSON.stringify(block.arguments)}` : ""))
			.filter(Boolean)
			.join("\n")}`;
	}
	const text = joinText(message.content);
	if (message.role === "toolResult") return `${message.toolName}: ${text.length > RESULT ? `${text.slice(0, RESULT / 2)} [${text.length - RESULT} characters cut] ${text.slice(-RESULT / 2)}` : text}`;
	return `${message.role === "user" ? "user" : (message.customType ?? message.role)}: ${text}`;
}

function transcript(file: string, from: number): string {
	let data = "";
	try {
		if (file.endsWith(".jsonl")) data = fs.readFileSync(file, "utf8");
	} catch {}
	if (!data) return `No transcript ${file}.`;
	const lines: string[] = [];
	for (const row of data.split("\n")) {
		try {
			const entry = JSON.parse(row) as { type?: string; message?: Logged };
			if (entry.type === "message" && entry.message) lines.push(flat(capText(said(entry.message))));
		} catch {}
	}
	if (!Number.isSafeInteger(from) || from < 0 || from >= lines.length) return `The transcript holds messages 0-${lines.length - 1}.`;
	const out: string[] = [];
	let size = 0;
	let at = from;
	for (; at < lines.length && (out.length === 0 || size + bytes(lines[at]) < RECENT); at++) {
		out.push(`${at}|${lines[at]}`);
		size += bytes(lines[at]) + 1;
	}
	if (at < lines.length) out.push(`zoom(${JSON.stringify(file)}, ${at}) shows the rest.`);
	return out.join("\n");
}

function rowsOf(message: Logged, name: string): string[] {
	const time = typeof message.timestamp === "number" ? message.timestamp : Date.now();
	return entriesOf(message).map(
		({ kind, text }) => `${JSON.stringify({ kind, text: capText(text), time, name } satisfies Entry)}\n`,
	);
}

function countLines(file: string): number {
	let data: Buffer;
	try {
		data = fs.readFileSync(file);
	} catch {
		return 0;
	}
	let n = 0;
	for (let at = data.indexOf(10); at >= 0; at = data.indexOf(10, at + 1)) n++;
	return n;
}

function rules(): string {
	let text = "";
	try {
		text = fs.readFileSync(RULES as string, "utf8").trim();
	} catch {}
	return `${RULES_INTRO}\n\n<rules>\n${text || "None yet."}\n</rules>`;
}

function sized(message: unknown): number {
	let images = 0;
	const json = JSON.stringify(message, (_key, value) => {
		if (value?.type !== "image" || typeof value.data !== "string") return value;
		images++;
		return undefined;
	});
	return bytes(json) + images * IMAGE;
}

const blocks = (content: unknown) => (typeof content === "string" ? [{ type: "text", text: content }] : (content as Block[]));

const turnStart = (messages: Logged[]) => messages.findLastIndex((message) => message.role === "user");

function turnMark(messages: Logged[]): number {
	const turn = turnStart(messages);
	return turn < 0 ? 0 : (messages[turn].timestamp ?? 0);
}

const tokensOf = (message: unknown) => Math.ceil(sized(message) / 4);

class Reader {
	readonly messages: Messages;
	readonly tree: Tail;
	readonly nodes = new Map<string, string>();

	constructor(readonly store: Store) {
		this.messages = new Messages(store);
		this.tree = new Tail(store.tree);
	}

	node(l: number, i: number): string | undefined {
		for (const row of this.tree.read()) {
			if (!row) continue;
			try {
				const parsed = JSON.parse(row) as { l: number; i: number; text: string };
				this.nodes.set(key(parsed.l, parsed.i), parsed.text);
			} catch {}
		}
		return this.nodes.get(key(l, i));
	}

	zoom(id: number, n: number): string {
		const total = readState(this.store)?.messages ?? 0;
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
			const message = this.messages.get(id);
			return message ? `${id}+1|${line(message)}` : `No message ${id}.`;
		}
		const half = n / 2;
		const l = Math.log2(half);
		return [id, id + half].map((at) => `${at}+${half}|${flat(this.node(l, at / half) ?? PLACEHOLDER)}`).join("\n");
	}

	date(id: number): string {
		const message = this.messages.get(id);
		return message ? when(message.time) : `No message ${id}.`;
	}
}

export default function optchat(pi: ExtensionAPI): void {
	const z = pi.zod;
	const own = new Reader(STORE);
	const readers = new Map<string, Reader>();
	let enabled = false;
	let snap: Snapshot | undefined;
	let home: { session: string; dir: string } | undefined;
	let fork: { self: string; parent: string } | undefined;
	let release: (() => void) | undefined;
	let primed = false;
	const saved = new Set<number>();

	const active = (ctx: ExtensionContext) => enabled && ctx.agent?.kind === "main";
	const result = (text: string) => ({ content: [{ type: "text" as const, text }] });
	const which = BOTS ? { bot: z.string().optional() } : {};
	const whose = BOTS ? "; with bot, that bot's memory, read-only" : "";

	function reader(bot: string | undefined): Reader | string {
		if (!bot || bot === BOT) return own;
		const dir = BOTS && !bot.startsWith(".") && !bot.includes("/") ? path.join(BOTS, bot, "optchat") : undefined;
		if (dir === undefined || !fs.existsSync(path.join(dir, "view.json"))) return `No bot named ${bot} keeps a memory.`;
		let found = readers.get(dir);
		if (found === undefined) {
			found = new Reader(open(dir));
			readers.set(dir, found);
		}
		return found;
	}

	function read(bot: string | undefined, run: (memory: Reader) => string) {
		const memory = reader(bot);
		return result(typeof memory === "string" ? memory : run(memory));
	}

	pi.registerTool({
		name: "zoom",
		label: "Zoom memory",
		description: `Open the line id+n of the memory view into the two lines of n/2 messages under it; n = 1 gives message id whole${whose}. A work line's helper transcript path as id opens that transcript from message n on.`,
		parameters: z.object({ id: z.union([z.number(), z.string()]), n: z.number(), ...which }),
		async execute(_toolCallId, params) {
			const id = params.id;
			if (typeof id === "string") return result(transcript(id, params.n));
			return read((params as { bot?: string }).bot, (memory) => memory.zoom(id, params.n));
		},
	});
	pi.registerTool({
		name: "date",
		label: "Memory date",
		description: `The date and time of memory message id${whose}.`,
		parameters: z.object({ id: z.number(), ...which }),
		async execute(_toolCallId, params) {
			return read((params as { bot?: string }).bot, (memory) => memory.date(params.id));
		},
	});
	pi.registerTool({
		name: "recent",
		label: "Recent memory",
		description: `The memory lines logged after this chat's view was taken${BOTS ? "; with bot, that bot's latest lines, read-only" : ""}.`,
		parameters: z.object({ ...which }),
		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			const bot = (params as { bot?: string }).bot;
			return read(bot, (memory) =>
				memory === own
					? recent(own.store, (BOT && active(ctx) ? snap?.upto : pins(ctx).at(-1)?.upto) ?? 0, "Nothing was logged after this chat's view was taken.")
					: recent(memory.store, 0, `${bot} has logged nothing yet.`),
			);
		},
	});
	if (BOTS) {
		pi.registerTool({
			name: "memories",
			label: "Bot memories",
			description: "The bots that keep a memory, with how many messages each holds; pass a name as bot to zoom, date or recent.",
			parameters: z.object({}),
			async execute() {
				const rows: string[] = [];
				let names: string[] = [];
				try {
					names = fs.readdirSync(BOTS).sort();
				} catch {}
				for (const name of names) {
					const state = readState(open(path.join(BOTS, name, "optchat")));
					if (state !== undefined) rows.push(`${name}: ${state.messages} messages${name === BOT ? " (you)" : ""}`);
				}
				return result(rows.length ? rows.join("\n") : "No bot keeps a memory yet.");
			},
		});
	}
	if (BOT && RULES) {
		pi.registerTool({
			name: "pin_rule",
			label: "Pin rule",
			description:
				"Add a standing rule the user just set you to your pinned rules, in their words, so it stays in your context word for word and is never summarized. Only for rules the user gave.",
			parameters: z.object({ rule: z.string() }),
			async execute(_toolCallId, params) {
				const rule = params.rule.trim().replace(/\s*\n\s*/g, " ");
				if (!rule) return result("No rule given.");
				fs.mkdirSync(path.dirname(RULES), { recursive: true });
				fs.appendFileSync(RULES, `- ${rule}\n`);
				return result(`Pinned: ${rule}`);
			},
		});
	}

	function backfill(ctx: ExtensionContext): void {
		const file = path.join(STORE.log, `${ctx.sessionManager.getSessionId()}.jsonl`);
		if (!fs.existsSync(file)) {
			const rows = ctx.sessionManager
				.getBranch()
				.flatMap((entry) => (entry.type === "message" ? rowsOf(entry.message as Logged, BOT as string) : []));
			fs.writeFileSync(file, rows.join(""));
		}
		saved.clear();
		for (const row of fs.readFileSync(file, "utf8").split("\n")) {
			try {
				saved.add((JSON.parse(row) as Entry).time);
			} catch {}
		}
	}

	function stored(message: Logged): boolean {
		return entriesOf(message).length > 0 && (typeof message.timestamp !== "number" || saved.has(message.timestamp));
	}

	function repin(messages: Logged[], session: string, floor: number): number {
		const state = readState(STORE);
		const view = readView(STORE);
		const rows = view.split("\n");
		const last = rows.findLast((row) => ROW.test(row));
		const match = last === undefined ? null : ROW.exec(last);
		const upto = match === null ? 0 : Number(match[1]) + Number(match[2]);
		const lag = Math.max(0, countLines(path.join(STORE.log, `${session}.jsonl`)) - (state?.seen?.[session] ?? 0));
		let pick = -1;
		let pickNeed = 0;
		let pickLogged = 0;
		let need = lag;
		let logged = 0;
		let size = 0;
		const turn = turnStart(messages);
		for (let k = messages.length - 1; k >= floor; k--) {
			size += sized(messages[k]);
			if (stored(messages[k])) {
				need--;
				logged++;
			}
			if (messages[k].role === "toolResult") continue;
			if (pick >= 0 && pickNeed <= 0 && k < turn && size > RAW / 2) break;
			pick = k;
			pickNeed = need;
			pickLogged = logged;
		}
		const hidden = new Set<number>();
		for (let at = upto - 1, left = pickLogged - lag; left > 0 && at >= 0; at--) {
			const message = own.messages.get(at);
			if (message === undefined) break;
			if (message.session !== session) continue;
			hidden.add(at);
			left--;
		}
		const from = pick < 0 ? Infinity : (messages[pick].timestamp ?? 0);
		const reported = new Map<string, Set<string>>();
		for (let k = Math.max(pick, 0); k < messages.length; k++) {
			const message = messages[k];
			const carries = message.role === "toolResult" ? message.toolName === "task" || message.toolName === "wait" : message.role === "custom" && message.customType === "async-result";
			if (!carries) continue;
			for (const result of joinText(message.content).matchAll(COMPLETED)) reported.set(result[1], (reported.get(result[1]) ?? new Set()).add(result[0]));
		}
		const prefix = `${session}.`;
		const reports = new Map<string, number[]>();
		for (let at = upto - 1; at >= 0; at--) {
			const message = own.messages.get(at);
			if (message === undefined || message.time < from) break;
			if (!message.session.startsWith(prefix)) continue;
			const id = message.session.slice(prefix.length);
			if (!reported.has(id)) continue;
			reports.set(id, [...(reports.get(id) ?? []), at]);
		}
		for (const [id, ats] of reports) if (ats.length <= (reported.get(id)?.size ?? 0)) for (const at of ats) hidden.add(at);
		const kept = rows.filter((row) => {
			const at = ROW.exec(row);
			if (at === null) return true;
			for (let k = Number(at[1]); k < Number(at[1]) + Number(at[2]); k++) if (!hidden.has(k)) return true;
			return false;
		});
		snap = { view: kept.join("\n"), upto, time: Date.now(), anchor: pick < 0 ? 0 : (messages[pick].timestamp ?? 0), turn: turnMark(messages) };
		return pick < 0 ? 0 : pick;
	}

	function window(messages: Logged[]): number {
		if (snap === undefined) return -1;
		const anchor = snap.anchor;
		let at = messages.findIndex((message) => (message.timestamp ?? 0) >= anchor);
		if (at < 0) at = messages.length;
		while (at < messages.length && messages[at].role === "toolResult") at++;
		if (at === messages.length) return -1;
		const mark = turnMark(messages);
		if (mark !== snap.turn && at < turnStart(messages)) {
			let size = 0;
			for (let k = at; k < messages.length; k++) size += sized(messages[k]);
			if (size > RAW) return -1;
		}
		snap.turn = mark;
		return at;
	}

	function frame(messages: Logged[], at: number): Logged[] {
		const pinned = snap as Snapshot;
		const head = [
			...(RULES ? [{ type: "text", text: rules() }] : []),
			{ type: "text", text: `${BOT_INTRO}\n\n${pinned.view}` },
		];
		const turn = turnStart(messages);
		const recentTurns = messages.slice(at);
		if (turn >= 0 && turn < at) {
			const asks = messages
				.slice(turn, at)
				.map(askText)
				.filter(Boolean)
				.map((text) => ({ type: "text", text }));
			recentTurns.unshift({ ...messages[turn], content: [...blocks(messages[turn].content), ...asks] });
		}
		const first = recentTurns[0];
		if (first?.role !== "user") return [{ role: "user", content: head, timestamp: pinned.time }, ...recentTurns];
		return [{ ...first, content: [...head, ...blocks(first.content)] }, ...recentTurns.slice(1)];
	}

	function tokens(out: Logged[], system: number): number {
		let total = 0;
		for (let k = out.length - 1; k >= 0; k--) {
			const used = out[k].role === "assistant" && (out[k].timestamp ?? 0) > (snap as Snapshot).time ? (out[k].usage?.totalTokens ?? 0) : 0;
			if (used > 0) return total + used;
			total += tokensOf(out[k]);
		}
		return total + system;
	}

	function bot(messages: Logged[], session: string, ctx: ExtensionContext): Logged[] {
		let at = window(messages);
		if (at < 0) at = repin(messages, session, 0);
		const span = ctx.model?.contextWindow ?? 0;
		if (span <= 0) return frame(messages, at);
		const limit = span - Math.min(ctx.model.maxTokens ?? span, span / 4);
		const system = tokensOf(ctx.getSystemPrompt() ?? "");
		let out = frame(messages, at);
		let need = tokens(out, system);
		if (need <= limit) return out;
		const floor = Math.max(at, turnStart(messages));
		let fold = -1;
		let rest = system + tokensOf(frame(messages, messages.length)[0]);
		for (let k = messages.length - 1; k > floor; k--) {
			rest += tokensOf(messages[k]);
			if (rest > limit) break;
			if (messages[k].role === "assistant" && (fold < 0 || rest <= limit / 2)) fold = k;
		}
		if (fold >= 0) {
			out = frame(messages, repin(messages, session, fold));
			need = tokens(out, system);
			if (need <= limit) return out;
		}
		ctx.abort();
		throw new Error(`optchat: ${BOT} would send about ${need} tokens to ${ctx.model.provider}/${ctx.model.id}, past the ${limit} its context window leaves after its output, even with its current run folded`);
	}

	function start(ctx: ExtensionContext): void {
		snap = undefined;
		const main = ctx.agent?.kind === "main";
		const file = ctx.sessionManager.getSessionFile();
		const parent = ctx.sessionManager.getHeader()?.parentSession;
		enabled = (!main || ctx.mode === "tui" || ctx.mode === "rpc") && file !== undefined && (BOT !== undefined || fs.existsSync(STORE.main));
		home = enabled && main && file !== undefined ? { session: ctx.sessionManager.getSessionId(), dir: file.replace(/\.jsonl$/, "") } : undefined;
		fork = enabled && !main && parent ? { self: ctx.sessionManager.getSessionId(), parent: path.basename(parent, ".jsonl").split("_").at(-1) ?? parent } : undefined;
		if (enabled && !main) pinned(ctx);
		if (!home || BOT === undefined) return;
		fs.mkdirSync(STORE.log, { recursive: true });
		backfill(ctx);
	}

	pi.on("session_start", async (_event, ctx) => start(ctx));
	pi.on("session_switch", async (_event, ctx) => start(ctx));

	pi.events.on(LIFECYCLE, (data) => {
		const run = data as Run;
		if (home === undefined || !run.sessionFile || path.dirname(run.sessionFile) !== home.dir) return;
		if (run.status !== "completed" && run.status !== "failed" && run.status !== "aborted") return;
		let report = "";
		try {
			report = fs.readFileSync(run.sessionFile.replace(/\.jsonl$/, ".md"), "utf8").trim();
		} catch {}
		const head = `Helper ${run.id}${run.description ? ` (${run.description})` : ""}`;
		const text = run.status === "completed" ? `${head} reported:\n${report}` : `${head} ${run.status} before reporting.`;
		const row: Entry = {
			kind: "work",
			text: capText(`${text}\n\nFull transcript: zoom(${JSON.stringify(run.sessionFile)}, 0)`),
			time: Date.now(),
			name: BOT ?? chatName(pi.getSessionName(), home.session),
		};
		fs.appendFileSync(path.join(STORE.log, `${home.session}.${run.id}.jsonl`), `${JSON.stringify(row)}\n`);
	});

	pi.on("message_end", async (event, ctx) => {
		if (!active(ctx)) return;
		const session = ctx.sessionManager.getSessionId();
		const rows = rowsOf(event.message as Logged, BOT ?? chatName(pi.getSessionName(), session));
		if (rows.length) {
			fs.appendFileSync(path.join(STORE.log, `${session}.jsonl`), rows.join(""));
			saved.add((event.message as Logged).timestamp);
		}
	});

	function pinned(ctx: ExtensionContext): Pin {
		let pin = pins(ctx).at(-1);
		if (pin === undefined) {
			pin = (fork && views.get(fork.parent)) ?? take();
			pi.appendEntry(PIN, pin);
		}
		views.set(ctx.sessionManager.getSessionId(), pin);
		return pin;
	}

	pi.on("before_provider_request", async (event, ctx) => {
		if (fork === undefined) return undefined;
		const meta = (event.payload as { metadata?: { user_id?: unknown } } | undefined)?.metadata;
		if (typeof meta?.user_id === "string") meta.user_id = meta.user_id.replaceAll(fork.self, fork.parent);
		if (!primed) {
			primed = true;
			const key = `${fork.parent}\0${ctx.agent?.name}\0${ctx.model?.provider}/${ctx.model?.id}\0${pins(ctx).at(-1)?.upto}`;
			const lead = leads.get(key);
			if (lead) await Promise.race([lead, Bun.sleep(PRIME)]);
			else {
				const gate = Promise.withResolvers<void>();
				leads.set(key, gate.promise);
				release = gate.resolve;
			}
		}
		return event.payload;
	});
	pi.on("message_end", async (event) => {
		if (event.message.role !== "assistant") return;
		release?.();
		release = undefined;
	});

	pi.on("context", async (event, ctx) => {
		if (!enabled) return undefined;
		if (!active(ctx)) {
			const pin = pinned(ctx);
			return { messages: [{ role: "user", content: [{ type: "text" as const, text: `${HELPER_INTRO}\n\n${pin.view}` }], timestamp: pin.time }, ...event.messages] };
		}
		if (BOT) {
			const messages = bot(event.messages as Logged[], ctx.sessionManager.getSessionId(), ctx);
			const { view, upto, time } = snap as Snapshot;
			views.set(ctx.sessionManager.getSessionId(), { view, upto, time });
			return { messages: messages as typeof event.messages };
		}
		const pin = pinned(ctx);
		const block = { type: "text" as const, text: `${INTRO}\n\n${pin.view}` };
		const at = event.messages.findIndex((message) => message.role === "user");
		if (at < 0) return { messages: [{ role: "user", content: [block], timestamp: pin.time }, ...event.messages] };
		const first = event.messages[at] as Extract<(typeof event.messages)[number], { role: "user" }>;
		const content = typeof first.content === "string" ? [{ type: "text" as const, text: first.content }] : first.content;
		return { messages: event.messages.with(at, { ...first, content: [block, ...content] }) };
	});

	pi.on("session_compact", async (_event, ctx) => {
		if (active(ctx) && !BOT) pi.appendEntry(PIN, take());
	});
}
