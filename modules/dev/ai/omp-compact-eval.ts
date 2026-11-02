import { toolRenderers } from "@oh-my-pi/pi-tui/tools";

const NATIVE = Symbol.for("finix.omp-compact-eval.native");
const LANGUAGES = { python: true, js: true };

function failed(result) {
	if (result?.isError || result?.details?.isError) return true;
	return (result?.details?.cells ?? []).some(cell => cell.status === "error");
}

function cellsOf(args) {
	if (Array.isArray(args?.cells)) return args.cells;
	return typeof args?.code === "string" ? [args] : [];
}

function titles(cells) {
	return cells.map(cell => (typeof cell?.title === "string" ? cell.title.trim() : "")).filter(Boolean);
}

function tidy(view, cells, extra) {
	if (!view) return view;
	const tool = view.tool && { ...view.tool };
	if (tool) {
		const badges = (tool.badges ?? []).filter(badge => LANGUAGES[badge.text] !== true);
		tool.badges = badges.length > 0 ? badges : undefined;
		const named = titles(cells);
		if ((!tool.title || tool.title === "Eval") && named.length > 0) tool.title = named[0];
	}
	return { ...view, tool, preview: "none", ...extra };
}

export default function compactEval() {
	const current = toolRenderers.eval;
	const native = current?.[NATIVE] ?? current;
	if (!native?.describeCall || !native.describeResult) return;
	toolRenderers.eval = {
		...native,
		[NATIVE]: native,
		describeCall(args, options) {
			return tidy(native.describeCall(args, options), cellsOf(args));
		},
		describeResult(result, options, args) {
			const cells = result?.details?.cells?.length ? result.details.cells : cellsOf(args);
			return tidy(native.describeResult(result, options, args), cells, { open: failed(result) || undefined });
		},
	};
}
