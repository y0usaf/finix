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

function install(state) {
	const transcript = TranscriptContainer.prototype;
	const assistant = AssistantMessageComponent.prototype;
	const describeAssistant = assistant.describe;
	const nativeBlocks = transcript.nativeBlocks;
	const groups = new WeakMap();
	const parts = new WeakMap();
	const failures = new WeakMap();
	const shownBy = new WeakMap();
	const nodeBy = new WeakMap();

	const describe = block => block.describe(state.cx);

	assistant.describe = function (cx) {
		if (cx) state.cx = cx;
		return describeAssistant.call(this, cx);
	};

	function speaks(block) {
		return (describe(block)?.c ?? []).some(child => !isComponent(child) && (child.k === "md" || child.key === "error"));
	}

	function thinks(block) {
		return (describe(block)?.c ?? []).some(isThinking);
	}

	class Part {
		constructor(source, thinking) {
			this.source = source;
			this.thinking = thinking;
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
			this.node = { ...whole, c: (whole?.c ?? []).filter(child => isThinking(child) === this.thinking) };
			return this.node;
		}
	}

	function part(source, thinking) {
		let pair = parts.get(source);
		if (!pair) {
			pair = [new Part(source, false), new Part(source, true)];
			parts.set(source, pair);
		}
		const chosen = pair[thinking ? 1 : 0];
		if (isNativeSettled(source) && !isNativeSettled(chosen)) settleNative(chosen);
		return chosen;
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
		}
		render() {
			return [];
		}
		invalidate() {}
		handleNativeEvent(event) {
			if (event.type === "toggle" && event.key === "work") this.toggled = event.collapsed;
		}
		update(blocks, live) {
			if (live && this.startedAt === undefined) this.startedAt = performance.now();
			if (!live && this.live) this.endedAt = performance.now();
			this.blocks = blocks;
			this.live = live;
		}
		describe(cx) {
			if (cx) state.cx = cx;
			const failed = this.blocks.filter(block => isTool(block) && block.describe(cx)?.p?.status === "error");
			const collapsed = this.toggled ?? !this.live;
			const wall =
				this.startedAt !== undefined && this.endedAt !== undefined ? this.endedAt - this.startedAt : undefined;
			const time = this.live ? undefined : (wall ?? spent(this.blocks, cx));
			const key = [...this.blocks, ...failed, collapsed, this.live, time];
			if (this.key && same(this.key, key)) return this.node;
			this.key = key;
			const steps = this.blocks.filter(isTool).length;
			const count = `${steps} ${steps === 1 ? "step" : "steps"}`;
			const label = this.live
				? [text([span("Working", "muted")]), elapsed(performance.now() - this.startedAt), text([span(`· ${count}`, "muted")])]
				: [text([span(time === undefined ? count : `Worked for ${duration(time)} · ${count}`, "muted")])];
			if (failed.length > 0) label.push(node("badge", { text: `${failed.length} failed`, tone: "error" }));
			const head = node("row", { gap: "sm", align: "center" }, label, "head");
			const body = collapsed ? this.blocks.filter(block => !failed.includes(block)) : this.blocks;
			this.node = col(
				[
					node("section", { role: "omp.notice.work", collapsible: true, collapsed }, [head, ...body], "work"),
					...(collapsed ? failed.map(folded) : []),
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
		let open = [];
		const close = last => {
			if (open.length === 0) return;
			if (open.some(isTool)) {
				const work = group(open[0]);
				work.update(open, last && state.running);
				shown.push(work);
			} else {
				shown.push(...open);
			}
			open = [];
		};
		for (const block of blocks) {
			if (isInitiator(block)) {
				close(false);
				shown.push(block);
			} else if (block instanceof AssistantMessageComponent && speaks(block)) {
				if (thinks(block)) open.push(part(block, true));
				close(false);
				shown.push(thinks(block) ? part(block, false) : block);
			} else if (isTool(block) || block instanceof AssistantMessageComponent || open.length > 0) {
				open.push(block);
			} else {
				shown.push(block);
			}
		}
		close(true);
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
