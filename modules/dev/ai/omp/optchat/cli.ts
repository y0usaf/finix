import { memory, transcript } from "./read.ts";

const usage = "usage: optchat zoom <id> <n> [--bot NAME] | optchat zoom <transcript.jsonl> <from> | optchat date <id> [--bot NAME]";
const args = process.argv.slice(2);
const at = args.indexOf("--bot");
const bot = at < 0 ? undefined : args.splice(at, 2)[1];
const [cmd, a, b] = args;

function fail(text: string): never {
	console.error(text);
	process.exit(2);
}

if (cmd === "zoom" && a !== undefined && b !== undefined) {
	if (!/^\d+$/.test(a)) {
		console.log(transcript(a, Number(b)));
	} else {
		const found = memory(bot);
		if (typeof found === "string") fail(found);
		for (const block of found.zoom(Number(a), Number(b))) console.log(block.type === "text" ? block.text : `[${block.type}]`);
	}
} else if (cmd === "date" && a !== undefined) {
	const found = memory(bot);
	if (typeof found === "string") fail(found);
	console.log(found.date(Number(a)));
} else {
	fail(usage);
}
