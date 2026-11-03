import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

export const DIR = process.env.OPTCHAT_DIR || path.join(os.homedir(), ".local/state/optchat");
export const CHUNK = 1024;
export const NODE = 512;
export const PLACEHOLDER = "(not summarized yet: zoom it)";
export const EMPTY_VIEW = "<chat>\n</chat>";

export interface Entry {
	kind: string;
	text: string;
	time: number;
	name: string;
}

export interface Message extends Entry {
	i: number;
	session: string;
	src: number;
}

export interface NodeLine {
	l: number;
	i: number;
	text: string;
}

export interface ViewState {
	messages: number;
	levels: number[];
	seen: Record<string, number>;
	built: boolean;
}

export interface Store {
	dir: string;
	log: string;
	main: string;
	tree: string;
	view: string;
	viewText: string;
	spend: string;
}

export function open(dir: string): Store {
	return {
		dir,
		log: path.join(dir, "log"),
		main: path.join(dir, "main"),
		tree: path.join(dir, "tree.jsonl"),
		view: path.join(dir, "view.json"),
		viewText: path.join(dir, "view.txt"),
		spend: path.join(dir, "spend.jsonl"),
	};
}

export const STORE = open(DIR);

export const chunkPath = (store: Store, k: number) => path.join(store.main, `${String(k).padStart(6, "0")}.jsonl`);
export const line = (m: Entry) => `${m.kind}[${m.name}]: ${m.text}`;
export const bytes = (text: string) => Buffer.byteLength(text, "utf8");
export const flat = (text: string) => text.replaceAll("\n", " ");
export const key = (l: number, i: number) => `${l},${i}`;

export function when(time: number): string {
	const date = new Date(time);
	const pad = (n: number) => String(n).padStart(2, "0");
	const weekday = date.toLocaleDateString("en-US", { weekday: "long" });
	const zone = Intl.DateTimeFormat().resolvedOptions().timeZone;
	return `${weekday} ${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())} ${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(date.getSeconds())} ${zone}`;
}

export function writeAtomic(file: string, text: string): void {
	const temp = `${file}.${process.pid}.tmp`;
	fs.writeFileSync(temp, text);
	fs.renameSync(temp, file);
}

export function readState(store: Store): ViewState | undefined {
	try {
		return JSON.parse(fs.readFileSync(store.view, "utf8")) as ViewState;
	} catch {
		return undefined;
	}
}

export function readView(store: Store): string {
	try {
		return fs.readFileSync(store.viewText, "utf8");
	} catch {
		return EMPTY_VIEW;
	}
}

export class Tail {
	offset = 0;

	constructor(readonly file: string) {}

	read(): string[] {
		let fd: number;
		try {
			fd = fs.openSync(this.file, "r");
		} catch {
			return [];
		}
		try {
			const size = fs.fstatSync(fd).size;
			if (size <= this.offset) return [];
			const buffer = Buffer.alloc(size - this.offset);
			const got = fs.readSync(fd, buffer, 0, buffer.length, this.offset);
			const end = buffer.subarray(0, got).lastIndexOf(10);
			if (end < 0) return [];
			this.offset += end + 1;
			return buffer.subarray(0, end).toString("utf8").split("\n");
		} finally {
			fs.closeSync(fd);
		}
	}

	skip(lines: number): void {
		let data: Buffer;
		try {
			data = fs.readFileSync(this.file);
		} catch {
			return;
		}
		let at = 0;
		for (let n = 0; n < lines; n++) {
			const next = data.indexOf(10, at);
			if (next < 0) break;
			at = next + 1;
		}
		this.offset = at;
	}
}

export class Messages {
	#cache = new Map<number, { size: number; rows: string[] }>();

	constructor(readonly store: Store) {}

	get(i: number): Message | undefined {
		const k = Math.floor(i / CHUNK);
		const file = chunkPath(this.store, k);
		let size: number;
		try {
			size = fs.statSync(file).size;
		} catch {
			return undefined;
		}
		let chunk = this.#cache.get(k);
		if (chunk?.size !== size) {
			chunk = { size, rows: fs.readFileSync(file, "utf8").split("\n") };
			this.#cache.set(k, chunk);
		}
		const row = chunk.rows[i % CHUNK];
		if (!row) return undefined;
		const message = JSON.parse(row) as Message;
		return message.i === i ? message : undefined;
	}
}
