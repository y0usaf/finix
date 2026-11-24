import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
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
import { chatTranscriptDisplayPreferences } from "@oh-my-pi/pi-tui/chat/display-preferences";
import { col, elapsed, node, span, text, withHidden } from "@oh-my-pi/pi-tui/native/describe";
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


function parseBool(raw) {
	if (typeof raw === "boolean") return raw;
	if (typeof raw !== "string") return undefined;
	const v = raw.trim().toLowerCase();
	if (v === "1" || v === "true" || v === "yes" || v === "on") return true;
	if (v === "0" || v === "false" || v === "no" || v === "off") return false;
	return undefined;
}

const LIVE_TAIL = 6;

function resolveLazyUnmount() {
	const env = parseBool(process.env.OMP_WORK_FOLD_LAZY_UNMOUNT);
	if (env !== undefined) return env;
	const dir = process.env.OMP_AGENT_DIR || join(homedir(), process.env.PI_CONFIG_DIR || ".omp", "agent");
	try {
		const raw = JSON.parse(readFileSync(join(dir, "work-fold.json"), "utf8"));
		const cfg = parseBool(raw?.lazyUnmount);
		if (cfg !== undefined) return cfg;
	} catch {}
	return true;
}

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
	const voices = new WeakMap();
	const failures = new WeakMap();
	const earlierFolds = new WeakMap();
	const shownBy = new WeakMap();
	const nodeBy = new WeakMap();

	const describe = block => block.describe(state.cx);

	assistant.describe = function (cx) {
		if (cx) state.cx = cx;
		return describeAssistant.call(this, cx);
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
			this.node = { ...whole, c: children };
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
			if (this.opened || whole?.p?.collapsible !== true) return whole;
			if (whole === this.whole && this.lazy === state.lazyUnmount) return this.node;
			this.whole = whole;
			this.lazy = state.lazyUnmount;
			const head = whole.k === "tool" ? [] : (whole.c ?? []).filter(child => child?.key === "head");
			this.node = { ...whole, p: { ...whole.p, collapsed: true }, ...(this.lazy ? { c: head } : {}) };
			return this.node;
		}
	}

	function folded(source, cache = failures) {
		let wrapper = cache.get(source);
		if (!wrapper) {
			wrapper = new Folded(source);
			cache.set(source, wrapper);
		}
		return wrapper;
	}

	function moreSteps(count) {
		const label = text([span(`${count} earlier ${count === 1 ? "step" : "steps"}`, "dim")]);
		return node(
			"section",
			{ role: "omp.notice.work.earlier", collapsible: true, collapsed: true },
			[node("row", { gap: "sm", align: "center" }, [label], "head")],
			"earlier",
		);
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
			if (event.type !== "toggle") return;
			if (event.key === "work") this.toggled = event.collapsed;
			else if (typeof event.key === "string" && event.key.endsWith("earlier") && !event.collapsed) this.all = true;
		}
		update(blocks, live, ended) {
			if (live && this.startedAt === undefined) this.startedAt = performance.now();
			if (!live && this.live) this.endedAt = performance.now();
			this.blocks = blocks;
			this.live = live;
			this.ended = ended;
		}
		describe(cx) {
			if (cx) state.cx = cx;
			const failed = this.blocks.filter(block => isTool(block) && block.describe(cx)?.p?.status === "error");
			const collapsed = this.toggled ?? !this.live;
			const wall =
				this.startedAt !== undefined && this.endedAt !== undefined ? this.endedAt - this.startedAt : undefined;
			const time = this.live ? undefined : (wall ?? spent(this.blocks, cx));
			const hidden = chatTranscriptDisplayPreferences.hideToolActivity;
			const lazy = state.lazyUnmount;
			const shown = collapsed && this.ended && !(hidden && lazy) ? failed : [];
			const key = [...this.blocks, ...failed, collapsed, this.live, this.ended, time, hidden, lazy, this.toggled, this.all];
			if (this.key && same(this.key, key)) return this.node;
			this.key = key;
			const steps = this.blocks.filter(isTool).length;
			const count = `${steps} ${steps === 1 ? "step" : "steps"}`;
			const work = this.live ? "Working" : time === undefined ? "Worked" : `Worked for ${duration(time)}`;
			const label = [text([span(work)], { truncate: "end", shrink: 1 })];
			if (this.live) label.push(elapsed(performance.now() - this.startedAt));
			label.push(text([span(count, "dim")], { basis: "content" }));
			if (failed.length > 0) label.push(node("badge", { text: `${failed.length} failed`, tone: "error" }));
			const head = node("row", { gap: "sm", align: collapsed ? "center" : "baseline" }, label, "head");
			const rest = this.blocks.filter(block => !shown.includes(block));
			const tools = rest.filter(isTool);
			const earlier = tools.length - LIVE_TAIL;
			const cut = earlier > 0 ? rest.indexOf(tools[earlier]) : 0;
			const tail = rest.slice(cut);
			const body =
				lazy && (collapsed || hidden)
					? []
					: !lazy || earlier <= 0
						? rest
						: this.live && this.toggled === undefined && !this.all
							? [moreSteps(earlier), ...tail]
							: [...rest.slice(0, cut).map(block => (isTool(block) ? folded(block, earlierFolds) : block)), ...tail];
			this.node = withHidden(
				col(
					[
						node("section", { role: "omp.notice.work", collapsible: true, collapsed }, [head, ...body], "work"),
						...shown.map(block => folded(block)),
					],
					{ gap: "sm" },
				),
				hidden,
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
		const flush = (ended, live) => {
			if (open.length === 0) return;
			if (open.some(isTool)) {
				const work = group(open[0]);
				work.update(open, live, ended);
				shown.push(work);
			} else {
				shown.push(...open);
			}
			open = [];
		};
		for (const block of blocks) {
			if (isInitiator(block)) {
				flush(true, false);
				shown.push(block);
			} else if (speaks(block)) {
				if (thinks(block)) open.push(voice(block, "thinking"));
				flush(true, false);
				shown.push(answer(block));
			} else if (isTool(block) || block instanceof AssistantMessageComponent || open.length > 0) {
				open.push(block);
			} else {
				shown.push(block);
			}
		}
		flush(!state.running, state.running);
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
		state = { running: false, cx: undefined, lazyUnmount: resolveLazyUnmount() };
		globalThis[STATE] = state;
		install(state);
	} else {
		state.lazyUnmount = resolveLazyUnmount();
	}
	pi.on("agent_start", async (_event, ctx) => {
		if (ctx.hasUI) state.running = true;
	});
	pi.on("agent_end", async (_event, ctx) => {
		if (ctx.hasUI) state.running = false;
	});
}
