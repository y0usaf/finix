import { EMPTY_VIEW, NODE, PLACEHOLDER, bytes, flat, key } from "./store.ts";

export interface Limits {
	max: number;
	min: number;
	draining: boolean;
}

export interface Part {
	l: number;
	i: number;
}

export interface Meta {
	time: number;
	session: string;
}

export const start = (p: Part) => p.i * 2 ** p.l;
export const end = (p: Part) => (p.i + 1) * 2 ** p.l;
export const partKey = (p: Part) => key(p.l, p.i);

export function cut(text: string): string {
	if (bytes(text) <= NODE) return text;
	return Buffer.from(text, "utf8").subarray(0, NODE).toString("utf8").replace(/\uFFFD+$/, "");
}

export class Tree {
	msgs: Meta[] = [];
	nodes: string[][] = [];
	view: Part[] = [];
	small: Part[] = [];
	big: Limits = { max: 128_000, min: 64_000, draining: false };
	little: Limits = { max: 32_000, min: 16_000, draining: false };

	constructor(readonly onBuilt: (p: Part, text: string) => void) {}

	has(p: Part): boolean {
		return p.l >= 0 && p.i >= 0 && p.l < this.nodes.length && p.i < this.nodes[p.l].length;
	}

	built(p: Part): boolean {
		return this.has(p) && this.nodes[p.l][p.i] !== "";
	}

	text(p: Part): string {
		return this.built(p) ? this.nodes[p.l][p.i] : PLACEHOLDER;
	}

	grow(): void {
		const n = this.msgs.length;
		for (let l = 0; 2 ** l <= n; l++) {
			if (l === this.nodes.length) this.nodes.push([]);
			const level = this.nodes[l];
			const want = Math.floor(n / 2 ** l);
			while (level.length < want) level.push("");
		}
	}

	add(meta: Meta, text: string): boolean {
		this.msgs.push(meta);
		this.grow();
		const i = this.msgs.length - 1;
		if (bytes(text) <= NODE) this.set({ l: 0, i }, text);
		this.view.push({ l: 0, i });
		this.small.push({ l: 0, i });
		return this.fit(this.msgs.length);
	}

	join(l: number, i: number): boolean {
		const a = this.nodes[l - 1][2 * i];
		const b = this.nodes[l - 1][2 * i + 1];
		if (this.nodes[l][i] !== "" || a === "" || b === "" || bytes(a) + 1 + bytes(b) > NODE) return false;
		this.nodes[l][i] = `${a}\n${b}`;
		this.onBuilt({ l, i }, this.nodes[l][i]);
		return true;
	}

	set(p: Part, text: string): void {
		this.nodes[p.l][p.i] = text;
		this.onBuilt(p, text);
		let at = p;
		while (
			at.l + 1 < this.nodes.length &&
			at.i >> 1 < this.nodes[at.l + 1].length &&
			this.join(at.l + 1, at.i >> 1)
		) {
			at = { l: at.l + 1, i: at.i >> 1 };
		}
	}

	freeMerges(): void {
		for (let l = 1; l < this.nodes.length; l++) {
			for (let i = 0; i < this.nodes[l].length; i++) this.join(l, i);
		}
	}

	fit(n: number): boolean {
		const merged = this.squeeze(this.view, n, this.big);
		if (merged) {
			this.small = [...this.view];
			this.little.draining = true;
		}
		this.squeeze(this.small, n, this.little);
		return merged;
	}

	squeeze(view: Part[], n: number, limits: Limits): boolean {
		let size = 0;
		let merged = false;
		for (const p of view) size += bytes(this.text(p));
		if (size > limits.max) limits.draining = true;
		while (limits.draining && size > limits.min) {
			let best = -1;
			let due = 0;
			for (let k = 0; k + 1 < view.length; k++) {
				const a = view[k];
				const b = view[k + 1];
				if (a.l !== b.l || a.i % 2 !== 0 || b.i !== a.i + 1 || !this.built({ l: a.l + 1, i: a.i / 2 })) continue;
				const d = (n - end(b) + 1) / 2 ** a.l;
				if (best < 0 || d > due) {
					best = k;
					due = d;
				}
			}
			if (best < 0) return merged;
			const a = view[best];
			const b = view[best + 1];
			const parent = { l: a.l + 1, i: a.i / 2 };
			size += bytes(this.text(parent)) - bytes(this.text(a)) - bytes(this.text(b));
			view.splice(best, 2, parent);
			merged = true;
		}
		limits.draining = false;
		return merged;
	}

	layout(): void {
		this.view = [];
		this.small = [];
		this.big.draining = false;
		this.little.draining = false;
		for (let i = 0; i < this.msgs.length; i++) {
			this.view.push({ l: 0, i });
			this.small.push({ l: 0, i });
			this.fit(i + 1);
		}
	}

	restore(levels: readonly number[]): boolean {
		const view: Part[] = [];
		let at = 0;
		for (const l of levels) {
			if (!Number.isInteger(l) || l < 0 || at % 2 ** l !== 0 || at + 2 ** l > this.msgs.length) return false;
			view.push({ l, i: at / 2 ** l });
			at += 2 ** l;
		}
		for (; at < this.msgs.length; at++) view.push({ l: 0, i: at });
		const down = (p: Part): Part[] =>
			p.l === 0 || this.built(p)
				? [p]
				: [
						{ l: p.l - 1, i: 2 * p.i },
						{ l: p.l - 1, i: 2 * p.i + 1 },
					].flatMap(down);
		this.view = view.flatMap(down);
		this.small = [...this.view];
		this.little.draining = true;
		this.fit(this.msgs.length);
		return true;
	}

	first(): number {
		for (const p of this.view) if (!this.built(p)) return start(p);
		return this.msgs.length;
	}

	ready(skip: (p: Part) => boolean, ahead: number): Part[] {
		const first = this.first();
		const out: Part[] = [];
		for (let l = 0; l < this.nodes.length; l++) {
			const level = this.nodes[l];
			for (let i = 0; i < level.length; i++) {
				if (level[i] !== "") continue;
				const p = { l, i };
				if (l > 0 && (!this.built({ l: l - 1, i: 2 * i }) || !this.built({ l: l - 1, i: 2 * i + 1 }))) continue;
				if (start(p) < first + ahead && !skip(p)) out.push(p);
			}
		}
		return out;
	}

	levels(): number[] {
		return this.view.map((p) => p.l);
	}

	render(levels: readonly number[], upto: number): string {
		if (upto === 0) return EMPTY_VIEW;
		let out = "<chat>\n";
		let at = 0;
		for (const l of levels) {
			const p = { l, i: at / 2 ** l };
			if (!this.has(p) || at % 2 ** l !== 0 || end(p) > upto) {
				throw new Error(`optchat: view does not tile messages 0-${upto}`);
			}
			out += `${start(p)}+${2 ** l}|${flat(this.text(p))}\n`;
			at = end(p);
		}
		if (at !== upto) throw new Error(`optchat: view covers ${at} of ${upto} messages`);
		return `${out}</chat>`;
	}

	upTo(upto: number): string {
		const levels: number[] = [];
		let at = 0;
		for (const p of this.small) {
			if (end(p) > upto || !this.built(p)) break;
			levels.push(p.l);
			at = end(p);
		}
		return this.render(levels, at);
	}
}
