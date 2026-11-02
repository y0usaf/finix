import { AssistantMessageComponent } from "@oh-my-pi/pi-tui/chat/assistant-message";
import { TranscriptContainer } from "@oh-my-pi/pi-tui/chrome";
import { col } from "@oh-my-pi/pi-tui/native/describe";

const ORIGINAL = Symbol.for("finix.omp-work-fold.original");

function isVoid(node) {
	return node?.k === "col" && (node.c === undefined || node.c.length === 0);
}

export default function workFold() {
	const transcript = TranscriptContainer.prototype;
	const assistant = AssistantMessageComponent.prototype;
	const original = transcript[ORIGINAL] ?? {
		nativeBlocks: transcript.nativeBlocks,
		transcriptDescribe: transcript.describe,
		assistantDescribe: assistant.describe,
	};
	transcript[ORIGINAL] = original;
	let lastCx;
	const shownBy = new WeakMap();
	const nodeBy = new WeakMap();

	assistant.describe = function (cx) {
		if (cx) lastCx = cx;
		return original.assistantDescribe.call(this, cx);
	};

	transcript.nativeBlocks = function () {
		const blocks = original.nativeBlocks.call(this);
		const shown = blocks.filter(
			block => !(block instanceof AssistantMessageComponent) || !isVoid(block.describe(lastCx)),
		);
		const previous = shownBy.get(this);
		if (previous && previous.length === shown.length && previous.every((block, i) => block === shown[i])) {
			return previous;
		}
		shownBy.set(this, shown);
		return shown;
	};

	transcript.describe = function () {
		const blocks = this.nativeBlocks();
		const cached = nodeBy.get(this);
		if (cached?.blocks === blocks) return cached.node;
		const node = col(blocks, { role: "omp.transcript" });
		nodeBy.set(this, { blocks, node });
		return node;
	};
}
