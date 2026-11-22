import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";
import * as fs from "node:fs";
import * as path from "node:path";
import * as readline from "node:readline";

const DEFAULT_LIMIT = 20;
const MAX_LIMIT = 50;
const DEFAULT_CONTEXT = 240;
const MAX_CONTEXT = 600;
const MAX_OUTPUT_CHARS = 16_000;
const MAX_LINE_CHARS = 8_000_000;
const ENV_SECRET_RE = /\b([A-Za-z0-9_]*(?:TOKEN|SECRET|PASSWORD|PASSWD|API_KEY|APIKEY|PRIVATE_KEY|CREDENTIALS?)[A-Za-z0-9_]*)(\\?["']?\s*[:=]\s*\\?["']?)(?:\\[^"'\s]|[^\s"'\\,}])+/gi;
const SECRET_RE = /\b(?:gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|glpat-[A-Za-z0-9_-]{20,}|sk-[A-Za-z0-9_-]{20,}|xox[abpr]-[A-Za-z0-9-]{10,}|AKIA[A-Z0-9]{16})\b/g;

interface MatchRow {
	tsMs: number;
	ts: string;
	speaker: string;
	relPath: string;
	lineNo: number;
	snippet: string;
}

function extractText(content: unknown): string {
	if (typeof content === "string") return content;
	if (!Array.isArray(content)) return "";
	const parts: string[] = [];
	for (const block of content) {
		if (block && typeof block === "object" && "type" in block && block.type === "text" && "text" in block) {
			if (typeof block.text === "string" && block.text.length > 0) parts.push(block.text);
		}
	}
	return parts.join("\n");
}

function parseTimestamp(raw: unknown): number {
	if (typeof raw === "number" && Number.isFinite(raw) && raw > 0) return raw;
	if (typeof raw === "string" && raw.trim().length > 0) {
		const trimmed = raw.trim();
		if (/^\d+$/.test(trimmed)) {
			const n = Number(trimmed);
			return Number.isFinite(n) && n > 0 ? n : 0;
		}
		const ms = Date.parse(trimmed);
		if (Number.isFinite(ms) && ms > 0) return ms;
	}
	return 0;
}

function collectJsonlFiles(root: string, includeHelpers: boolean): string[] {
	const files: string[] = [];
	if (!fs.existsSync(root)) return files;
	let entries: fs.Dirent[] = [];
	try {
		entries = fs.readdirSync(root, { withFileTypes: true });
	} catch {
		return files;
	}
	for (const entry of entries) {
		if (entry.name === "archive" || entry.name.startsWith(".")) continue;
		const full = path.join(root, entry.name);
		if (entry.isFile() && entry.name.endsWith(".jsonl")) {
			files.push(full);
		} else if (includeHelpers && entry.isDirectory()) {
			let sub: fs.Dirent[] = [];
			try {
				sub = fs.readdirSync(full, { withFileTypes: true });
			} catch {
				continue;
			}
			for (const s of sub) {
				if (s.isFile() && s.name.endsWith(".jsonl")) {
					files.push(path.join(full, s.name));
				}
			}
		}
	}
	return files.sort();
}

function makeSnippet(text: string, matchIndex: number, matchLen: number, windowChars: number): string {
	const half = Math.max(20, Math.floor((windowChars - matchLen) / 2));
	const start = Math.max(0, matchIndex - half);
	const end = Math.min(text.length, matchIndex + matchLen + half);
	const raw = text.slice(start, end).replace(/\s+/g, " ").trim();
	const prefix = start > 0 ? "..." : "";
	const suffix = end < text.length ? "..." : "";
	return `${prefix}${raw}${suffix}`;
}

function resolveSessionsDir(requested?: string): string | { error: string } {
	const stateRoot = process.env.OMP_BOT_STATE || path.join(process.env.XDG_STATE_HOME || path.join(process.env.HOME || "/", ".local/state"), "omp-bot");
	const botsRoot = process.env.GREPMEM_BOTS ?? path.join(stateRoot, "bots");
	const bot = requested || (process.env.GREPMEM_SESSIONS_DIR ? undefined : process.env.OMP_BOT_NAME);
	if (bot) {
		if (!botsRoot || bot.startsWith(".") || bot.includes("/") || bot.includes("\\")) {
			return { error: `Unknown or disallowed bot: ${bot}` };
		}
		const dir = path.join(botsRoot, bot, "sessions");
		if (!fs.existsSync(dir)) return { error: `No sessions directory for bot: ${bot}` };
		return dir;
	}
	const explicit = process.env.GREPMEM_SESSIONS_DIR?.trim();
	if (explicit) {
		if (!fs.existsSync(explicit)) return { error: `GREPMEM_SESSIONS_DIR does not exist: ${explicit}` };
		return explicit;
	}
	return { error: "GrepMem is not configured: set GREPMEM_SESSIONS_DIR or GREPMEM_BOTS with a valid bot parameter." };
}

function parseRecord(raw: string): { ts: string; tsMs: number; role: string; speaker: string; text: string } | undefined {
	let obj: Record<string, unknown>;
	try {
		obj = JSON.parse(raw) as Record<string, unknown>;
	} catch {
		return undefined;
	}
	const type = obj.type;
	const ts = typeof obj.timestamp === "string" ? obj.timestamp : "";
	const tsMs = parseTimestamp(obj.timestamp);
	if (type === "message") {
		const msg = obj.message as Record<string, unknown> | undefined;
		if (!msg || typeof msg !== "object") return undefined;
		const role = typeof msg.role === "string" ? msg.role : "unknown";
		const text = extractText(msg.content);
		if (!text) return undefined;
		const speaker = role === "toolResult" && typeof msg.toolName === "string" ? `tool:${msg.toolName}` : role;
		return { ts, tsMs, role, speaker, text };
	}
	if (type === "custom_message") {
		const customType = typeof obj.customType === "string" ? obj.customType : "custom";
		const text = extractText(obj.content);
		if (!text) return undefined;
		return { ts, tsMs, role: "custom", speaker: `custom:${customType}`, text };
	}
	return undefined;
}

export default function grepmem(pi: ExtensionAPI): void {
	const z = pi.zod;

	pi.registerTool({
		name: "grepmem",
		label: "Grep raw history",
		description:
			"Read-only regex/keyword search over raw bot session JSONL transcripts. Returns timestamped, speaker-labelled snippets with session path and line number.",
		parameters: z.object({
			pattern: z.string().describe("Regex pattern or keyword to search for"),
			literal: z.boolean().optional().describe("Treat pattern as a literal substring instead of regex"),
			case_sensitive: z.boolean().optional().describe("Case-sensitive matching (default false)"),
			role: z.enum(["all", "user", "assistant", "toolResult", "custom"]).optional().describe("Filter by message role (default all)"),
			since: z.string().optional().describe("ISO timestamp lower bound (inclusive)"),
			until: z.string().optional().describe("ISO timestamp upper bound (inclusive)"),
			include_helpers: z.boolean().optional().describe("Also search helper sub-transcripts (default false)"),
			limit: z.number().int().min(1).max(MAX_LIMIT).optional().describe("Maximum matches to return (default 20, max 50)"),
			context_chars: z.number().int().min(40).max(MAX_CONTEXT).optional().describe("Snippet width in characters (default 240, max 600)"),
			bot: z.string().optional().describe("Optional bot name when GREPMEM_BOTS is configured"),
		}),
		async execute(_toolCallId, params) {
			const dirOrErr = resolveSessionsDir(params.bot);
			if (typeof dirOrErr !== "string") {
				return { content: [{ type: "text" as const, text: dirOrErr.error }] };
			}
			const sessionsDir = dirOrErr;

			let re: RegExp;
			try {
				const src = params.literal ? params.pattern.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") : params.pattern;
				re = new RegExp(src, params.case_sensitive ? "" : "i");
			} catch (err) {
				return { content: [{ type: "text" as const, text: `Invalid regex: ${err instanceof Error ? err.message : String(err)}` }] };
			}

			let sinceMs = 0;
			if (params.since !== undefined) {
				sinceMs = parseTimestamp(params.since);
				if (sinceMs <= 0) {
					return { content: [{ type: "text" as const, text: `Invalid since timestamp: ${params.since}` }] };
				}
			}

			let untilMs = Number.POSITIVE_INFINITY;
			if (params.until !== undefined) {
				untilMs = parseTimestamp(params.until);
				if (untilMs <= 0) {
					return { content: [{ type: "text" as const, text: `Invalid until timestamp: ${params.until}` }] };
				}
			}

			let maxTsMs = Number.POSITIVE_INFINITY;
			const maxTsEnv = process.env.GREPMEM_MAX_TS;
			if (maxTsEnv !== undefined && maxTsEnv.length > 0) {
				const envMs = parseTimestamp(maxTsEnv);
				if (envMs <= 0) {
					return { content: [{ type: "text" as const, text: `Invalid GREPMEM_MAX_TS configuration: ${maxTsEnv}` }] };
				}
				maxTsMs = envMs;
			}

			const hasTemporalBound = sinceMs > 0 || Number.isFinite(untilMs) || Number.isFinite(maxTsMs);
			const roleFilter = params.role ?? "all";
			const includeHelpers = params.include_helpers ?? false;
			const limit = Math.min(MAX_LIMIT, Math.max(1, params.limit ?? DEFAULT_LIMIT));
			const contextChars = Math.min(MAX_CONTEXT, Math.max(40, params.context_chars ?? DEFAULT_CONTEXT));

			const files = collectJsonlFiles(sessionsDir, includeHelpers);
			const kept: MatchRow[] = [];
			let totalMatches = 0;
			let skippedFiles = 0;
			let skippedLines = 0;
			const newer = (a: { tsMs: number; lineNo: number }, b: { tsMs: number; lineNo: number }) =>
				a.tsMs - b.tsMs || a.lineNo - b.lineNo;

			for (const file of files) {
				const relPath = path.relative(sessionsDir, file);
				let lineNo = 0;
				try {
					const rl = readline.createInterface({ input: fs.createReadStream(file, { encoding: "utf8" }), crlfDelay: Infinity });
					for await (const raw of rl) {
						lineNo++;
						if (!raw) continue;
						if (raw.length > MAX_LINE_CHARS) {
							skippedLines++;
							continue;
						}
						const rec = parseRecord(raw);
						if (!rec) continue;
						if (roleFilter !== "all" && rec.role !== roleFilter) continue;
						if (hasTemporalBound && rec.tsMs <= 0) continue;
						if (sinceMs > 0 && rec.tsMs < sinceMs) continue;
						if (Number.isFinite(untilMs) && rec.tsMs > untilMs) continue;
						if (Number.isFinite(maxTsMs) && rec.tsMs >= maxTsMs) continue;
						rec.text = rec.text.replace(ENV_SECRET_RE, "$1$2[redacted]").replace(SECRET_RE, "[redacted]");
						const m = re.exec(rec.text);
						if (!m) continue;
						totalMatches++;
						const key = { tsMs: rec.tsMs, lineNo };
						let worst = -1;
						if (kept.length >= limit) {
							worst = 0;
							for (let k = 1; k < kept.length; k++) if (newer(kept[k], kept[worst]) < 0) worst = k;
							if (newer(key, kept[worst]) <= 0) continue;
						}
						const row: MatchRow = {
							tsMs: rec.tsMs,
							ts: rec.ts || "unknown-time",
							speaker: rec.speaker,
							relPath,
							lineNo,
							snippet: makeSnippet(rec.text, m.index, m[0].length, contextChars),
						};
						if (worst >= 0) kept[worst] = row;
						else kept.push(row);
					}
				} catch {
					skippedFiles++;
				}
			}

			const selected = kept.sort((a, b) => newer(b, a));
			const skipNote =
				skippedFiles || skippedLines ? ` (skipped ${skippedFiles} unreadable file(s), ${skippedLines} oversized line(s))` : "";

			if (selected.length === 0) {
				return { content: [{ type: "text" as const, text: `No matches for ${JSON.stringify(params.pattern)} in ${files.length} session file(s).${skipNote}` }] };
			}

			const out: string[] = [`Matches: ${selected.length} shown of ${totalMatches} total across ${files.length} file(s)${skipNote} (newest first):`];
			let chars = out[0].length;
			for (const row of selected) {
				const formatted = `[${row.ts}] ${row.speaker} (${row.relPath}:${row.lineNo}): ${row.snippet}`;
				if (chars + formatted.length + 1 > MAX_OUTPUT_CHARS) {
					out.push("...(output truncated at 16000 chars)");
					break;
				}
				out.push(formatted);
				chars += formatted.length + 1;
			}

			return { content: [{ type: "text" as const, text: out.join("\n") }] };
		},
	});
}
