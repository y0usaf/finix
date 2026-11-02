import { AssistantMessageComponent } from "@oh-my-pi/pi-tui/chat/assistant-message";
import { LateDiagnosticsMessageComponent } from "@oh-my-pi/pi-tui/chat/late-diagnostics-message";
import { ReadToolGroupComponent } from "@oh-my-pi/pi-tui/chat/read-tool-group";
import { TodoReminderComponent } from "@oh-my-pi/pi-tui/chat/todo-reminder";
import { ToolExecutionComponent } from "@oh-my-pi/pi-tui/chat/tool-execution";
import { TtsrNotificationComponent } from "@oh-my-pi/pi-tui/chat/ttsr-notification";
import { TranscriptContainer } from "@oh-my-pi/pi-tui/chrome";
import { col, elapsed, node, span, text } from "@oh-my-pi/pi-tui/native/describe";
import { isNativeSettled, settleNative } from "@oh-my-pi/pi-tui/native/settle";

const STATE = Symbol.for("finix.omp-work-fold.state");

const TOOLS = [ToolExecutionComponent, ReadToolGroupComponent];
const WORK = [
	...TOOLS,
	AssistantMessageComponent,
	TtsrNotificationComponent,
	LateDiagnosticsMessageComponent,
	TodoReminderComponent,
];

function isTool(block) {
	return TOOLS.some(kind => block instanceof kind);
}

function isWork(block) {
	return WORK.some(kind => block instanceof kind);
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
	const setTurnUsage = assistant.setTurnUsage;
	const nativeBlocks = transcript.nativeBlocks;
	const usage = new WeakMap();
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

	assistant.setTurnUsage = function (summary) {
		if (summary) usage.set(this, summary);
		else usage.delete(this);
		return setTurnUsage.call(this, summary);
	};

	function answers(block) {
		if (!(block instanceof AssistantMessageComponent)) return false;
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

	class Work {
		constructor() {
			this.blocks = [];
			this.live = false;
			this.startedAt = performance.now();
		}
		render() {
			return [];
		}
		invalidate() {}
		handleNativeEvent(event) {
			if (event.type === "toggle" && event.key === "work") this.toggled = event.collapsed;
		}
		update(blocks, live, spent) {
			if (live && !this.live) this.startedAt = state.running ? state.startedAt : performance.now();
			if (!live && this.live && spent === undefined) this.measured = performance.now() - this.startedAt;
			this.blocks = blocks;
			this.live = live;
			this.spent = spent ?? this.measured;
		}
		describe(cx) {
			if (cx) state.cx = cx;
			const failed = this.blocks.filter(
				block => block instanceof ToolExecutionComponent && block.describe(cx)?.p?.status === "error",
			);
			const collapsed = this.toggled ?? !this.live;
			const key = [...this.blocks, ...failed, collapsed, this.live, this.spent];
			if (this.key && same(this.key, key)) return this.node;
			this.key = key;
			const steps = this.blocks.filter(isTool).length;
			const label = this.live
				? [text([span("Working", "muted")]), elapsed(performance.now() - this.startedAt)]
				: [
						text([
							span(
								this.spent === undefined
									? `Worked · ${steps} ${steps === 1 ? "step" : "steps"}`
									: `Worked for ${duration(this.spent)}`,
								"muted",
							),
						]),
					];
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
		let i = 0;
		while (i < blocks.length) {
			if (!isWork(blocks[i])) {
				shown.push(blocks[i++]);
				continue;
			}
			let end = i;
			while (end < blocks.length && isWork(blocks[end])) end++;
			const run = blocks.slice(i, end);
			const lastTool = run.findLastIndex(isTool);
			if (lastTool < 0) {
				shown.push(...run);
				i = end;
				continue;
			}
			let answer = -1;
			for (let k = run.length - 1; k > lastTool; k--) {
				if (answers(run[k])) {
					answer = k;
					break;
				}
			}
			const inside = answer < 0 ? run : run.slice(0, answer);
			const after = answer < 0 ? [] : run.slice(answer);
			if (answer >= 0 && thinks(run[answer])) {
				inside.push(part(run[answer], true));
				after[0] = part(run[answer], false);
			}
			const spent = run.map(block => usage.get(block)?.elapsedMs).find(ms => typeof ms === "number");
			const work = group(run[0]);
			work.update(inside, state.running && end === blocks.length, spent);
			shown.push(work, ...after);
			i = end;
		}
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
		state = { running: false, startedAt: performance.now(), cx: undefined };
		globalThis[STATE] = state;
		install(state);
	}
	pi.on("agent_start", async (_event, ctx) => {
		if (!ctx.hasUI) return;
		state.running = true;
		state.startedAt = performance.now();
	});
	pi.on("agent_end", async (_event, ctx) => {
		if (!ctx.hasUI) return;
		state.running = false;
	});
}
