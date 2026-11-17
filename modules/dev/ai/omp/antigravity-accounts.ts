import { spawnSync } from "node:child_process";

/**
 * Google Antigravity accounts for the ACP provider.
 *
 * Crest Auth keeps the list of accounts and which one is active; each account
 * is a GEMINI_HOME folder, and the ACP provider manages its own Google login
 * and token refresh inside that folder. This extension only tells OMP which
 * folder is active, so nothing here reads, writes or copies a Google token.
 */
function activeAccountDir(): string | undefined {
	const result = spawnSync("crest-auth", ["json", "antigravity"], { encoding: "utf8" });
	if (result.status !== 0 || !result.stdout) return undefined;
	try {
		const parsed = JSON.parse(result.stdout) as { dir?: unknown };
		return typeof parsed.dir === "string" && parsed.dir !== "" ? parsed.dir : undefined;
	} catch {
		return undefined;
	}
}

export default function antigravityAccounts(pi) {
	// An explicit GEMINI_HOME wins: `crest-auth login antigravity-acp NAME` sets
	// one so a new account signs in inside its own folder rather than the active
	// account's, and anything else that names a folder keeps its own choice.
	const apply = () => {
		if (process.env.GEMINI_HOME?.trim()) return;
		const dir = activeAccountDir();
		if (dir !== undefined) process.env.GEMINI_HOME = dir;
	};
	apply();
	pi.on("session_start", apply);
}
