import { AssistantMessageComponent } from "@oh-my-pi/pi-tui/chat/assistant-message";
import { BashExecutionComponent } from "@oh-my-pi/pi-tui/chat/bash-execution";
import { CollabPromptMessageComponent } from "@oh-my-pi/pi-tui/chat/collab-prompt-message";
import {
	BranchSummaryMessageComponent,
	CompactionSummaryMessageComponent,
	HandoffSummaryMessageComponent,
} from "@oh-my-pi/pi-tui/chat/compaction-summary-message";
import { EvalExecutionComponent } from "@oh-my-pi/pi-tui/chat/eval-execution";
import { ReadToolGroupComponent } from "@oh-my-pi/pi-tui/chat/read-tool-group";
import { SkillMessageComponent } from "@oh-my-pi/pi-tui/chat/skill-message";
import { ToolExecutionComponent } from "@oh-my-pi/pi-tui/chat/tool-execution";
import { CollapsedSyntheticMessageComponent, UserMessageComponent } from "@oh-my-pi/pi-tui/chat/user-message";
import { TranscriptContainer } from "@oh-my-pi/pi-tui/chrome";
import { col, elapsed, node, span, text } from "@oh-my-pi/pi-tui/native/describe";
import { isNativeSettled, settleNative } from "@oh-my-pi/pi-tui/native/settle";

const STATE = Symbol.for("finix.omp-work-fold.state");

const TOOLS = [ToolExecutionComponent, ReadToolGroupComponent];
const INITIATORS = [
	UserMessageComponent,
	CollapsedSyntheticMessageComponent,
	SkillMessageComponent,
	CollabPromptMessageComponent,
	BashExecutionComponent,
	EvalExecutionComponent,
	CompactionSummaryMessageComponent,
	HandoffSummaryMessageComponent,
	BranchSummaryMessageComponent,
];

function isTool(block) {
	return TOOLS.some(kind => block instanceof kind);
}

function isInitiator(block) {
	return INITIATORS.some(kind => block instanceof kind);
}

function isComponent(child) {
	return typeof child?.render === "function";
}

function isThinking(child) {
	return !isComponent(child) && child?.k === "section" && String(child.p?.role ?? "").startsWith("omp.thinking");
}

function duration(ms) {
	const seconds = ms / 1000;
	if (seconds < 10) return `${Math.max(0, seconds).toFixed(1)}s`;
	if (seconds < 60) return `${Math.round(seconds)}s`;
	const minutes = Math.floor(seconds / 60);
	if (minutes < 60) return `${minutes}m ${String(Math.round(seconds % 60)).padStart(2, "0")}s`;
	return `${Math.floor(minutes / 60)}h ${String(minutes % 60).padStart(2, "0")}m`;
}

function same(a, b) {
	return a.length === b.length && a.every((item, i) => item === b[i]);
}

const INLINE = /`([^`]+)`|\[([^\]]+)\]\(([^)\s]+)[^)]*\)/g;

function headline(markdown) {
	const line =
		String(markdown ?? "")
			.split("\n")
			.map(row => row.replace(/^\s*(?:#{1,6}\s+|>\s*|[-*+]\s+|\d+[.)]\s+)/, "").trim())
			.find(row => row.length > 0 && !row.startsWith("```")) ?? "";
	const spans = [];
	let at = 0;
	for (const match of line.matchAll(INLINE)) {
		if (match.index > at) spans.push(span(line.slice(at, match.index).replace(/(\*\*|__|~~)/g, "")));
		spans.push(match[1] !== undefined ? span(match[1], "code") : span(match[2], "link", { href: match[3] }));
		at = match.index + match[0].length;
	}
	if (at < line.length) spans.push(span(line.slice(at).replace(/(\*\*|__|~~)/g, "")));
	return spans;
}

function install(state) {
	const transcript = TranscriptContainer.prototype;
	const assistant = AssistantMessageComponent.prototype;
	const describeAssistant = assistant.describe;
	const setTurnUsage = assistant.setTurnUsage;
	const nativeBlocks = transcript.nativeBlocks;
	const ends = new WeakSet();
	const groups = new WeakMap();
	const voices = new WeakMap();
	const failures = new WeakMap();
	const shownBy = new WeakMap();
	const nodeBy = new WeakMap();

	const describe = block => block.describe(state.cx);

	assistant.describe = function (cx) {
		if (cx) state.cx = cx;
		return describeAssistant.call(this, cx);
	};

	assistant.setTurnUsage = function (summary) {
		if (summary) ends.add(this);
		else ends.delete(this);
		return setTurnUsage.call(this, summary);
	};

	function speaks(block) {
		if (!(block instanceof AssistantMessageComponent)) return false;
		return (describe(block)?.c ?? []).some(child => !isComponent(child) && (child.k === "md" || child.key === "error"));
	}

	function thinks(block) {
		return (describe(block)?.c ?? []).some(isThinking);
	}

	class Voice {
		constructor(source, mode) {
			this.source = source;
			this.mode = mode;
		}
		render() {
			return [];
		}
		invalidate() {}
		handleNativeEvent(event) {
			this.source.handleNativeEvent?.(event);
		}
		describe(cx) {
			if (cx) state.cx = cx;
			const whole = this.source.describe(cx);
			if (whole === this.whole) return this.node;
			this.whole = whole;
			const thinking = this.mode === "thinking";
			const children = (whole?.c ?? []).filter(child => isThinking(child) === thinking);
			const p = this.mode === "note" ? { ...whole?.p, role: "omp.assistant.note" } : whole?.p;
			this.node = { ...whole, p, c: children };
			return this.node;
		}
	}

	function voice(source, mode) {
		let modes = voices.get(source);
		if (!modes) {
			modes = {};
			voices.set(source, modes);
		}
		modes[mode] ??= new Voice(source, mode);
		const chosen = modes[mode];
		if (isNativeSettled(source) && !isNativeSettled(chosen)) settleNative(chosen);
		return chosen;
	}

	function answer(block) {
		return thinks(block) ? voice(block, "prose") : block;
	}

	class Folded {
		constructor(source) {
			this.source = source;
			this.opened = false;
		}
		render() {
			return [];
		}
		invalidate() {}
		handleNativeEvent(event) {
			if (event.type === "toggle" && event.key === "") this.opened = !event.collapsed;
			this.source.handleNativeEvent?.(event);
		}
		describe(cx) {
			if (cx) state.cx = cx;
			const whole = this.source.describe(cx);
			if (this.opened || !whole?.p) return whole;
			if (whole === this.whole) return this.node;
			this.whole = whole;
			this.node = { ...whole, p: { ...whole.p, collapsed: true } };
			return this.node;
		}
	}

	function folded(source) {
		let wrapper = failures.get(source);
		if (!wrapper) {
			wrapper = new Folded(source);
			failures.set(source, wrapper);
		}
		return wrapper;
	}

	function spent(blocks, cx) {
		let total = 0;
		for (const block of blocks) {
			const described = block.describe(cx);
			if (isTool(block)) total += described?.p?.took ?? 0;
			else for (const child of described?.c ?? []) if (isThinking(child)) total += child.p?.took ?? 0;
		}
		return total >= 1000 ? total : undefined;
	}

	class Work {
		constructor() {
			this.blocks = [];
			this.live = false;
			this.ended = false;
		}
		render() {
			return [];
		}
		invalidate() {}
		handleNativeEvent(event) {
			if (event.type === "toggle" && event.key === "work") this.toggled = event.collapsed;
		}
		update(lead, blocks, live, ended) {
			if (live && this.startedAt === undefined) this.startedAt = performance.now();
			if (!live && this.live) this.endedAt = performance.now();
			this.lead = lead;
			this.blocks = blocks;
			this.live = live;
			this.ended = ended;
		}
		describe(cx) {
			if (cx) state.cx = cx;
			const note = this.lead && voice(this.lead.prose, "note");
			const thought = this.lead?.thought;
			const said = note ? note.describe(cx) : undefined;
			const failed = this.blocks.filter(block => isTool(block) && block.describe(cx)?.p?.status === "error");
			const collapsed = this.toggled ?? !this.live;
			const wall =
				this.startedAt !== undefined && this.endedAt !== undefined ? this.endedAt - this.startedAt : undefined;
			const time = this.live ? undefined : (wall ?? spent(this.blocks, cx));
			const shown = collapsed && this.ended ? failed : [];
			const key = [said, thought, ...this.blocks, ...failed, collapsed, this.live, this.ended, time];
			if (this.key && same(this.key, key)) return this.node;
			this.key = key;
			const steps = this.blocks.filter(isTool).length;
			const count = `${steps} ${steps === 1 ? "step" : "steps"}`;
			const prose = String(said?.c?.find(child => !isComponent(child) && child.k === "md")?.p?.text ?? "").trim();
			const lead = note ? headline(prose) : [];
			const whole = prose.split("\n").filter(line => line.trim().length > 0).length <= 1;
			const label = [];
			if (lead.length > 0) {
				const fit = collapsed ? { lines: 1, truncate: "end", title: prose } : { wrap: "word" };
				label.push(text(lead, { ...fit, shrink: 1 }));
			} else {
				label.push(text([span(this.live ? "Working" : time === undefined ? "Worked" : `Worked for ${duration(time)}`)]));
			}
			if (this.live) label.push(elapsed(performance.now() - this.startedAt));
			const meta = lead.length > 0 && time !== undefined ? `${count} · ${duration(time)}` : count;
			label.push(text([span(meta, "dim")], { basis: "content" }));
			if (failed.length > 0) label.push(node("badge", { text: `${failed.length} failed`, tone: "error" }));
			const head = node("row", { gap: "sm", align: collapsed ? "center" : "baseline" }, label, "head");
			const body = [
				...(thought ? [thought] : []),
				...(note && !whole ? [note] : []),
				...this.blocks.filter(block => !shown.includes(block)),
			];
			this.node = col(
				[
					node("section", { role: "omp.notice.work", collapsible: true, collapsed }, [head, ...body], "work"),
					...shown.map(folded),
				],
				{ gap: "sm" },
			);
			return this.node;
		}
	}

	function group(first) {
		let work = groups.get(first);
		if (!work) {
			work = new Work();
			groups.set(first, work);
		}
		return work;
	}

	transcript.nativeBlocks = function () {
		const blocks = nativeBlocks.call(this);
		const shown = [];
		let pending;
		let open = [];
		const emit = asAnswer => {
			if (pending.thought) shown.push(pending.thought);
			shown.push(asAnswer ? answer(pending.prose) : voice(pending.prose, "note"));
			pending = undefined;
		};
		const close = (ended, last) => {
			if (open.some(isTool)) {
				const work = group(pending?.prose ?? open[0]);
				work.update(pending, open, last && state.running, ended);
				shown.push(work);
				pending = undefined;
			} else {
				if (pending) emit(ended);
				shown.push(...open);
			}
			open = [];
		};
		for (const block of blocks) {
			if (isInitiator(block)) {
				if (open.length > 0) close(true, false);
				else if (pending) emit(true);
				shown.push(block);
			} else if (speaks(block)) {
				const thought = thinks(block) ? voice(block, "thinking") : undefined;
				if (open.length > 0) {
					if (thought) open.push(thought);
					close(false, false);
					pending = { prose: block };
				} else {
					if (pending) emit(false);
					pending = { prose: block, thought };
				}
				if (ends.has(block)) emit(true);
			} else if (isTool(block) || block instanceof AssistantMessageComponent || open.length > 0 || pending) {
				open.push(block);
			} else {
				shown.push(block);
			}
		}
		if (open.length > 0) close(!state.running, true);
		else if (pending) emit(!state.running);
		const previous = shownBy.get(this);
		if (previous && same(previous, shown)) return previous;
		shownBy.set(this, shown);
		return shown;
	};

	transcript.describe = function () {
		const blocks = this.nativeBlocks();
		const cached = nodeBy.get(this);
		if (cached?.blocks === blocks) return cached.node;
		const described = col(blocks, { role: "omp.transcript" });
		nodeBy.set(this, { blocks, node: described });
		return described;
	};
}

export default function workFold(pi) {
	let state = globalThis[STATE];
	if (!state) {
		state = { running: false, cx: undefined };
		globalThis[STATE] = state;
		install(state);
	}
	pi.on("agent_start", async (_event, ctx) => {
		if (ctx.hasUI) state.running = true;
	});
	pi.on("agent_end", async (_event, ctx) => {
		if (ctx.hasUI) state.running = false;
	});
}
