import { AssistantMessageComponent } from "@oh-my-pi/pi-tui/chat/assistant-message";
import { chatTranscriptDisplayPreferences } from "@oh-my-pi/pi-tui/chat/display-preferences";
import { UserMessageComponent } from "@oh-my-pi/pi-tui/chat/user-message";
import { TranscriptContainer } from "@oh-my-pi/pi-tui/chrome";
import { col } from "@oh-my-pi/pi-tui/native/describe";
import { isNativeSettled, settleNative } from "@oh-my-pi/pi-tui/native/settle";
import { Composer } from "@oh-my-pi/pi-tui/prompt/composer";

const STATE = Symbol.for("finix.omp-chat-look.state");
const HIDDEN =
	"\n# Tool activity\nYour tool calls are hidden from the transcript, so say in words what you found and what you ran rather than pointing at a card.\n";

class Marked {
	constructor(items, role) {
		this.items = items;
		this.node = col(items, { role });
	}

	invalidate() {
		for (const item of this.items) item.invalidate?.();
	}

	render(width) {
		return this.items.flatMap(item => item.render(width));
	}

	describe() {
		return this.node;
	}
}

function same(a, b) {
	return a.length === b.length && a.every((item, i) => item === b[i]);
}

function said(block) {
	const source = block?.mode === "thinking" ? undefined : (block?.source ?? block);
	return source instanceof UserMessageComponent || source instanceof AssistantMessageComponent;
}

function install() {
	const transcript = TranscriptContainer.prototype;
	const composer = Composer.prototype;
	const nativeBlocks = transcript.nativeBlocks;
	const describeSurface = composer.describeSurface;
	const marked = new WeakMap();
	const advice = new WeakMap();
	const shownBy = new WeakMap();
	const docks = new WeakMap();

	function advises(block) {
		let is = advice.get(block);
		if (is === undefined) {
			is = block.describe?.()?.p?.role === "omp.advisor";
			advice.set(block, is);
		}
		return is;
	}

	function mark(block) {
		const role = said(block) ? "omp.chat.msg" : advises(block) ? "omp.chat.advice" : undefined;
		if (!role) return block;
		let wrapped = marked.get(block);
		if (!wrapped) {
			wrapped = new Marked([block], role);
			marked.set(block, wrapped);
		}
		if (isNativeSettled(block) && !isNativeSettled(wrapped)) settleNative(wrapped);
		return wrapped;
	}

	transcript.nativeBlocks = function () {
		const blocks = nativeBlocks.call(this);
		const cached = shownBy.get(this);
		if (cached?.blocks === blocks) return cached.shown;
		const marks = blocks.map(mark);
		const shown = cached && same(cached.shown, marks) ? cached.shown : marks;
		shownBy.set(this, { blocks, shown });
		return shown;
	};

	composer.describeSurface = function (cx) {
		const surface = describeSurface.call(this, cx);
		let wrapped = docks.get(surface);
		if (!wrapped) {
			wrapped = { main: surface.main, dock: [new Marked(surface.dock, "omp.chat.dock")] };
			docks.set(surface, wrapped);
		}
		return wrapped;
	};
}

export default function chatLook(pi) {
	pi.setLabel("Chat look");

	pi.on("session_start", async () => {
		if (globalThis[STATE]) return;
		globalThis[STATE] = true;
		install();
	});

	pi.on("before_agent_start", async (event, ctx) => {
		if (ctx.agent?.kind === "sub" || ctx.mode !== "tui" || !chatTranscriptDisplayPreferences.hideToolActivity) return undefined;
		if (!Array.isArray(event.systemPrompt) || event.systemPrompt.length === 0) return undefined;
		const systemPrompt = [...event.systemPrompt];
		systemPrompt[systemPrompt.length - 1] = `${systemPrompt[systemPrompt.length - 1]}${HIDDEN}`;
		return { systemPrompt };
	});
}
