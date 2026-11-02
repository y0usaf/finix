import { toolRenderers } from "@oh-my-pi/pi-tui/tools";

const NATIVE = Symbol.for("finix.omp-compact-eval.native");

function failed(result) {
	if (result?.isError || result?.details?.isError) return true;
	return (result?.details?.cells ?? []).some(cell => cell.status === "error");
}

export default function compactEval() {
	const current = toolRenderers.eval;
	const native = current?.[NATIVE] ?? current;
	if (!native?.describeCall || !native.describeResult) return;
	toolRenderers.eval = {
		...native,
		[NATIVE]: native,
		describeCall(args, options) {
			const view = native.describeCall(args, options);
			return view && { ...view, preview: "none" };
		},
		describeResult(result, options, args) {
			const view = native.describeResult(result, options, args);
			return view && { ...view, preview: "none", open: failed(result) || undefined };
		},
	};
}
