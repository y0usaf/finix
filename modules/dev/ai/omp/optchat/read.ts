import * as fs from "node:fs";
import * as path from "node:path";
import { Messages, PLACEHOLDER, type Store, Tail, bytes, flat, key, line, open, readImage, readState, STORE, when } from "./store.ts";

export const CAP = 30_000;
const RECENT = 64_000;
export const RESULT = 2_000;
export const BOT = process.env.OPTCHAT_BOT;
export const BOTS = process.env.OPTCHAT_BOTS;

export interface Block {
	type: string;
	text?: string;
	data?: string;
	mimeType?: string;
	name?: string;
	arguments?: unknown;
}

export type ToolBlock = { type: "text"; text: string } | { type: "image"; data: string; mimeType: string };

export interface Logged {
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

export function joinText(content: unknown): string {
	if (typeof content === "string") return content;
	if (!Array.isArray(content)) return "";
	return content
		.map((block: Block) => (block?.type === "text" ? (block.text ?? "") : block?.type === "image" ? "[image]" : ""))
		.filter(Boolean)
		.join("\n");
}

export function capText(text: string): string {
	const chars = [...text];
	if (chars.length <= CAP) return text;
	const half = CAP / 2;
	return `${chars.slice(0, half).join("")}\n\n[${chars.length - CAP} characters cut]\n\n${chars.slice(chars.length - half).join("")}`;
}

export function said(message: Logged): string {
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

export const shq = (text: string) => `'${text.replaceAll("'", "'\\''")}'`;

export function transcript(file: string, from: number): string {
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
	if (at < lines.length) out.push(`optchat zoom ${shq(file)} ${at} shows the rest.`);
	return out.join("\n");
}

export class Reader {
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

	zoom(id: number, n: number): ToolBlock[] {
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
			return [{ type: "text", text: `No line ${id}+${n}.` }];
		}
		if (n === 1) {
			const message = this.messages.get(id);
			if (!message) return [{ type: "text", text: `No message ${id}.` }];
			const out: ToolBlock[] = [{ type: "text", text: `${id}+1|${line(message)}` }];
			for (const ref of message.images ?? []) {
				const image = readImage(this.store, ref);
				if (image) out.push(image);
			}
			return out;
		}
		const half = n / 2;
		const l = Math.log2(half);
		return [
			{
				type: "text",
				text: [id, id + half].map((at) => `${at}+${half}|${flat(this.node(l, at / half) ?? PLACEHOLDER)}`).join("\n"),
			},
		];
	}

	date(id: number): string {
		const message = this.messages.get(id);
		return message ? when(message.time) : `No message ${id}.`;
	}
}
const readers = new Map<string, Reader>();

export function memory(bot?: string): Reader | string {
	const dir = !bot || bot === BOT ? STORE.dir : BOTS && !bot.startsWith(".") && !bot.includes("/") ? path.join(BOTS, bot, "optchat") : undefined;
	if (dir === undefined || (dir !== STORE.dir && !fs.existsSync(path.join(dir, "view.json")))) return `No bot named ${bot} keeps a memory.`;
	let found = readers.get(dir);
	if (found === undefined) {
		found = new Reader(dir === STORE.dir ? STORE : open(dir));
		readers.set(dir, found);
	}
	return found;
}
