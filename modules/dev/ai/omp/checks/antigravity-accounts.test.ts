import { execFileSync } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import antigravityAccounts from "../antigravity-accounts.ts";

const STATE = mkdtempSync(join(tmpdir(), "antigravity-accounts-"));
process.env.CREST_AUTH_HOME = STATE;
delete process.env.GEMINI_HOME;

let failures = 0;
const check = (name, got, want) => {
	const ok = JSON.stringify(got) === JSON.stringify(want);
	if (!ok) {
		failures++;
		console.log(`FAIL ${name}\n  want: ${JSON.stringify(want)}\n  got:  ${JSON.stringify(got)}`);
	} else console.log(`ok ${name}`);
};
const order = () =>
	readFileSync(`${STATE}/order`, "utf8")
		.split("\n")
		.filter(Boolean);

const resetState = () => {
	rmSync(STATE, { recursive: true, force: true });
	execFileSync("mkdir", ["-p", STATE]);
	for (const name of ["work", "spare", "third"]) {
		execFileSync("crest-auth", ["json", "add", name], { env: process.env });
		execFileSync("sh", [
			"-c",
			`printf '{"id_token":"stub"}\\n' > ${STATE}/antigravity/${name}/antigravity-acp/acp_token.json`,
		]);
	}
};

const load = () => {
	const handlers = {};
	const sent = [];
	const state = { activeTools: ["counter", "bash", "read"] };
	antigravityAccounts({
		on: (name, fn) => {
			handlers[name] = fn;
		},
		registerCommand: () => {},
		sendMessage: (message, options) => sent.push({ message, options }),
		getActiveTools: () => [...state.activeTools],
		setActiveTools: async names => {
			state.activeTools = [...names];
		},
	});
	return {
		handlers,
		sent,
		state,
		toolRan: () => handlers.tool_execution_end?.({}, {}),
		userSaid: source => handlers.input?.({ source, text: "next", type: "input" }),
	};
};

const assistantError = (errorMessage) => ({
	role: "assistant",
	provider: "antigravity-acp",
	stopReason: "error",
	errorMessage,
	content: [],
	usage: { input: 1, output: 0 },
});

// 1. adopt the active account at load, and leave an explicit one alone.
resetState();
{
	const { sent } = load();
	check("load adopts the active folder", process.env.GEMINI_HOME, `${STATE}/antigravity/third`);
	check("load sends nothing", sent.length, 0);
}
{
	process.env.GEMINI_HOME = join(tmpdir(), "explicit-gemini-home");
	const { sent } = load();
	check("explicit GEMINI_HOME wins", process.env.GEMINI_HOME, join(tmpdir(), "explicit-gemini-home"));
	check("explicit load sends nothing", sent.length, 0);
	delete process.env.GEMINI_HOME;
}

// 2. an unrelated failure, or a turn that continues, does nothing.
{
	const { handlers, sent } = load();
	await handlers.agent_end({ willContinue: false, messages: [assistantError("HTTP 500 server error")] });
	check("unrelated error sends nothing", sent.length, 0);
	await handlers.agent_end({ willContinue: true, messages: [assistantError("quota exceeded")] });
	check("a continuing turn is left alone", sent.length, 0);
}

// 3. a quota failure after a tool ran switches the account and stops the turn,
//    because the ACP agent decides what the next request runs.
{
	const { handlers, sent, state, toolRan } = load();
	handlers.agent_start({});
	toolRan();
	await handlers.agent_end({ willContinue: false, messages: [assistantError("quota exceeded: resource exhausted")] });
	const visible = sent.filter(item => item.message.display === true);
	check("tool then quota switches the account", process.env.GEMINI_HOME, `${STATE}/antigravity/spare`);
	check("tool then quota stops the turn", sent.some(item => item.options?.triggerTurn === true), false);
	check("tool then quota says why it stopped", /every tool is switched off here to keep it from running twice/.test(visible.at(-1).message.content), true);
	check("tool then quota names the next account", /spare serves this session now/.test(visible.at(-1).message.content), true);
	check("tool then quota order leads with the successor", order()[0], "spare");
	check("tool then quota switches every tool off", state.activeTools, []);
	handlers.agent_start({});
	check("an automatic agent start keeps them off", state.activeTools, []);
	await handlers.input({ source: "extension", text: "hidden", type: "input" });
	check("an extension injection keeps them off", state.activeTools, []);
	await handlers.input({ source: "interactive", text: "carry on", type: "input" });
	check("a user message brings them back", state.activeTools, ["counter", "bash", "read"]);
}

// 4. a quota failure with nothing run yet continues on the next account.
{
	const { handlers, sent } = load();
	handlers.agent_start({});
	await handlers.agent_end({ willContinue: false, messages: [assistantError("quota exceeded: rate limit")] });
	const hidden = sent.filter(item => item.message.display === false);
	check("no-tool quota switches the account", process.env.GEMINI_HOME, `${STATE}/antigravity/work`);
	check("no-tool quota continues once", [hidden.length, hidden[0]?.options], [1, { deliverAs: "nextTurn", triggerTurn: true }]);
	check("no-tool quota continuation mentions nothing ran", /Nothing ran yet in this turn/.test(hidden[0].message.content), true);
}

// 5. a gated account is named as verification, with Google's link, and a fresh
//    turn continues on another account instead of a silent model fallback.
{
	resetState();
	const { handlers, sent } = load();
	handlers.agent_start({});
	await handlers.agent_end({
		willContinue: false,
		messages: [
			assistantError(
				"Antigravity ACP no longer advertises model gemini-4-hydrogen. Verify your account to continue: https://accounts.google.com/verify?token=xyz",
			),
		],
	});
	const visible = sent.filter(item => item.message.display === true);
	check("gated switches past the gated account", process.env.GEMINI_HOME, `${STATE}/antigravity/spare`);
	check("gated names verification, not a missing model", /needs Google verification, so the ACP runtime advertised no models/.test(visible[0].message.content), true);
	check("gated shows Google's page as a link", /\[open it\]\(https:\/\/accounts\.google\.com\/verify\?token=xyz\)/.test(visible[0].message.content), true);
	check("gated continues when nothing ran", sent.some(item => item.options?.triggerTurn === true), true);
	const until = Number(
		readFileSync(`${STATE}/limits`, "utf8")
			.split("\n")
			.map(line => line.split("\t"))
			.find(fields => fields[0] === "antigravity-acp:third")?.[2] ?? 0,
	);
	check("gated account sits out for an hour", until - Date.now() > 3_000_000, true);
}

// 6. a gated account after a tool ran stops the turn as well.
{
	const { handlers, sent, toolRan } = load();
	handlers.agent_start({});
	toolRan();
	await handlers.agent_end({
		willContinue: false,
		messages: [assistantError("Antigravity ACP no longer advertises model gemini-4-hydrogen; verify your account")],
	});
	check("gated after a tool stops", sent.some(item => item.options?.triggerTurn === true), false);
	check("gated after a tool says why", /A tool already ran in this turn/.test(sent.at(-1).message.content), true);
}

// 7. when nothing is left, the turn stops visibly and never continues.
{
	const { handlers, sent } = load();
	handlers.agent_start({});
	await handlers.agent_end({ willContinue: false, messages: [assistantError("quota exceeded: insufficient_quota")] });
	const visible = sent.filter(item => item.message.display === true);
	check("exhausted announces a stop", visible.length, 1);
	check("exhausted does not continue", sent.some(item => item.options?.triggerTurn === true), false);
	check("exhausted names the way out", /\/login|\/antigravity NAME/.test(visible[0].message.content), true);
}

if (failures > 0) {
	console.log(`${failures} check(s) failed`);
	process.exit(1);
}
console.log("all failover checks passed");
