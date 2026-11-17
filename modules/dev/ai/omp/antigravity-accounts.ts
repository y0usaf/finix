import { spawnSync } from "node:child_process";
import { readFileSync, readdirSync } from "node:fs";

const PROVIDER = "antigravity-acp";
const LIMIT =
	/quota|resource.?exhausted|insufficient_quota|rate.?limit|too many requests|limit reached|exceeded your|\b429\b|\b402\b/i;
const GATED =
	/no longer advertises|was not discovered|authentication required|not signed in|not logged in|unauthenticated|verif|invalid_grant|sign in|consent/i;

/**
 * Google Antigravity accounts for the ACP provider.
 *
 * Crest Auth keeps the list of accounts and which one is active; each account
 * is a GEMINI_HOME folder, and the ACP provider manages its own Google login
 * and token refresh inside that folder. This extension tells OMP which folder
 * is active, moves to the next account when the active one reports a quota or
 * needs Google verification, and hands Google's pages to the chat as links.
 * Failover continues the conversation instead of replaying the turn, so a tool
 * that already ran is never run again. Nothing here reads a Google token.
 */
function crest(args: string[], extraEnv?: Record<string, string>): Record<string, unknown> | undefined {
	const result = spawnSync("crest-auth", args, {
		encoding: "utf8",
		env: extraEnv ? { ...process.env, ...extraEnv } : process.env,
	});
	if (result.status !== 0 || !result.stdout) return undefined;
	try {
		return JSON.parse(result.stdout);
	} catch {
		return undefined;
	}
}

function descendants(pid: number): number[] {
	const seen = [pid];
	for (let index = 0; index < seen.length; index++) {
		let tasks: string[] = [];
		try {
			tasks = readdirSync(`/proc/${seen[index]}/task`);
		} catch {
			continue;
		}
		for (const task of tasks) {
			try {
				const children = readFileSync(`/proc/${seen[index]}/task/${task}/children`, "utf8").trim();
				if (children) for (const child of children.split(/\s+/)) seen.push(Number(child));
			} catch {}
		}
	}
	return seen.slice(1);
}

function stopRuntime(): void {
	for (const pid of descendants(process.pid)) {
		let command = "";
		try {
			command = readFileSync(`/proc/${pid}/cmdline`, "utf8");
		} catch {
			continue;
		}
		if (!/agy_acp_server\.par|supervisor\.mjs/.test(command)) continue;
		try {
			process.kill(pid, "SIGTERM");
		} catch {}
	}
}

export default function antigravityAccounts(pi) {
	// An explicit GEMINI_HOME wins: anything that names a folder, including the
	// dispatcher behind `crest-auth login antigravity-acp NAME`, keeps its own
	// choice, and so does a user who set it before starting OMP.
	// A folder login is pinned to that folder's file store; the keyring account
	// keeps the shared Secret Service item. Whichever account Crest calls active
	// decides which of the two the ACP server may use, so a stale pin is dropped
	// on every move. Only an account Crest marks keyring goes without the pin:
	// anything else, including a name just added here, must not fall back to the
	// shared login.
	const adoptAccount = (account: unknown) => {
		const row = account as { dir?: unknown; storage?: unknown } | undefined;
		if (typeof row?.dir !== "string" || row.dir === "") return;
		process.env.GEMINI_HOME = row.dir;
		if (row.storage === "keyring") delete process.env.AGY_ACP_FORCE_FILE_STORAGE;
		else process.env.AGY_ACP_FORCE_FILE_STORAGE = "1";
	};
	const adopt = () => {
		if (process.env.GEMINI_HOME?.trim()) return;
		adoptAccount(crest(["json", "antigravity"]));
	};
	adopt();
	pi.on("session_start", adopt);

	// A tool that ran is never run again by an account switch. OMP recovers an
	// error turn on its own, so the guard cannot live in this handler: after a
	// switch that followed a tool, every tool is switched off and stays off
	// across the automatic agent starts until the user sends something.
	let usedTool = false;
	let toolsOff = false;
	let savedTools: string[] | undefined;
	pi.on("agent_start", () => {
		usedTool = false;
	});
	pi.on("tool_execution_end", () => {
		usedTool = true;
	});
	pi.on("input", async event => {
		if (!toolsOff || event.source === "extension") return;
		toolsOff = false;
		if (savedTools !== undefined) {
			await pi.setActiveTools(savedTools);
			savedTools = undefined;
		}
	});

	pi.registerCommand("antigravity", {
		description: "List the Crest Antigravity accounts, or add one: /antigravity NAME",
		handler: async (args, ctx) => {
			const wanted = args.trim();
			if (wanted === "") {
				const accounts = crest(["json", "antigravity"])?.accounts;
				const rows = Array.isArray(accounts) ? (accounts as Array<Record<string, unknown>>) : [];
				ctx.ui.notify(
					rows.length === 0
						? "No Antigravity accounts yet. Add one with /antigravity NAME."
						: rows
								.map(
									account =>
										`${account.active ? "→ " : "  "}${String(account.name)}${account.signedIn ? "" : " (not signed in)"}`,
								)
								.join("\n"),
					"info",
				);
				return;
			}
			const added = crest(["json", "add", wanted]);
			if (typeof added?.dir !== "string") {
				ctx.ui.notify(`Could not add an Antigravity account named ${wanted}.`, "error");
				return;
			}
			adoptAccount(added);
			ctx.ui.notify(
				`Antigravity account ${wanted} is active in ${added.dir}. Sign it in with /login → Google Antigravity (ACP); the login shows Google's page as a link here.`,
				"info",
			);
		},
	});

	pi.on("agent_end", async (event, _ctx) => {
		if (event.willContinue) return;
		const failed = [...(event.messages ?? [])]
			.reverse()
			.find(message => message.role === "assistant" && message.provider === PROVIDER && message.stopReason === "error");
		if (!failed) return;
		const said = failed.errorMessage ?? "";
		const link = said.match(/https:\/\/[^\s)<>"']*(?:google|antigravity)[^\s)<>"']*/i)?.[0];
		const limited = LIMIT.test(said);
		const gated = GATED.test(said);
		if (!limited && !gated) return;
		// A gated account will not heal by itself, so it sits out for an hour
		// instead of the default cooldown; a quota only cools for the default.
		const ranTool = usedTool;
		if (ranTool) {
			toolsOff = true;
			if (savedTools === undefined) {
				savedTools = pi.getActiveTools();
				await pi.setActiveTools([]);
			}
		}
		const toolNote = " A tool already ran in this turn, so every tool is switched off here to keep it from running twice; send your next message and the tools come back.";
		const next = crest(["json", "rotate"], limited ? undefined : { CREST_AUTH_COOLDOWN: "3600" });
		if (typeof next?.to !== "string" || typeof next.dir !== "string") {
			pi.sendMessage({
				customType: "antigravity-accounts",
				display: true,
				content: `${
					link === undefined ? "" : `Google wants an account confirmed: [open Google's page](${link}).\n\n`
				}Every Antigravity account is out of quota or needs a Google sign-in (${String(next?.until ?? "no successor")}). This turn stops here: sign the account in with /login → Google Antigravity (ACP), or add another with /antigravity NAME.${ranTool ? toolNote : ""}`,
			});
			return;
		}
		adoptAccount(next);
		stopRuntime();
		const why = limited ? "hit its quota" : "needs Google verification, so the ACP runtime advertised no models";
		const switchNote = `Account ${String(next.from)} ${why}. ${next.to} serves this session now.${
			link === undefined ? "" : ` Google's page for ${String(next.from)}: [open it](${link}).`
		}${limited ? "" : ` Sign ${String(next.from)} in again with /login → Google Antigravity (ACP) when convenient.`}`;
		if (ranTool) {
			pi.sendMessage({ customType: "antigravity-accounts", display: true, content: `${switchNote}${toolNote}` });
			return;
		}
		pi.sendMessage({ customType: "antigravity-accounts", display: true, content: switchNote });
		pi.sendMessage(
			{
				customType: "antigravity-accounts",
				display: false,
				content: `Account ${String(next.from)} stopped this turn and ${next.to} serves it now. Nothing ran yet in this turn, so continue from where it stopped.`,
			},
			{ deliverAs: "nextTurn", triggerTurn: true },
		);
	});
}
