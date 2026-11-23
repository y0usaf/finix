import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";
import * as fs from "node:fs";
import * as path from "node:path";
import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";

const DEFAULT_LIMIT = 20;
const MAX_LIMIT = 50;
const DEFAULT_CONTEXT = 240;
const MAX_CONTEXT = 600;
const MAX_OUTPUT_CHARS = 16_000;
const MAX_LINE_CHARS = 8_000_000;
const DEADLINE_MS = 30_000;
const SNAPSHOT_MS = 250;
const CHUNK_BYTES = 1 << 20;
const LINE_BREAK_RE = /[\r\n\u2028\u2029]/g;
const ENV_SECRET_RE = /\b([A-Za-z0-9_]*(?:TOKEN|SECRET|PASSWORD|PASSWD|API_KEY|APIKEY|PRIVATE_KEY|CREDENTIALS?)[A-Za-z0-9_]*)(\\?["']?\s*[:=]\s*\\?["']?)(?:\\[^"'\s]|[^\s"'\\,}])+/gi;
const ENV_SECRET_HINT_RE = /TOKEN|SECRET|PASSWORD|PASSWD|API_KEY|APIKEY|PRIVATE_KEY|CREDENTIAL/i;
const SECRET_RE = /\b(?:gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|glpat-[A-Za-z0-9_-]{20,}|sk-[A-Za-z0-9_-]{20,}|xox[abpr]-[A-Za-z0-9-]{10,}|AKIA[A-Z0-9]{16})\b/g;

interface MatchRow {
	tsMs: number;
	ts: string;
	speaker: string;
	relPath: string;
	lineNo: number;
	snippet: string;
	oversized?: boolean;
}

function formatRow(row: MatchRow): string {
	return `[${row.ts}] ${row.speaker} (${row.relPath}:${row.lineNo}): ${row.snippet}`;
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
	if (requested) return { error: `Cross-bot search is not enabled for this bot: ${requested}` };
	const name = process.env.OMP_BOT_NAME;
	if (!name || name.startsWith(".") || name.includes("/")) return { error: "GrepMem needs OMP_BOT_NAME." };
	const stateRoot = process.env.OMP_BOT_STATE || path.join(process.env.XDG_STATE_HOME || path.join(process.env.HOME || "/", ".local/state"), "omp-bot");
	const dir = path.join(stateRoot, "bots", name, "sessions");
	if (!fs.existsSync(dir)) return { error: `No sessions directory for bot: ${name}` };
	return dir;
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

interface ScanJob {
	sessionsDir: string;
	includeHelpers: boolean;
	source: string;
	flags: string;
	roleFilter: string;
	sinceMs: number;
	untilMs: number | null;
	maxTsMs: number | null;
	limit: number;
	contextChars: number;
	deadlineMs: number;
}

interface Snapshot {
	files: number;
	filesDone: number;
	kept: MatchRow[];
	totalMatches: number;
	skippedFiles: number;
	skippedLines: number;
	done: boolean;
}

interface ScanRun {
	snap?: Snapshot;
	stopped?: "timeout" | "aborted";
	error?: string;
}

const newer = (a: { tsMs: number; lineNo: number }, b: { tsMs: number; lineNo: number }) => a.tsMs - b.tsMs || a.lineNo - b.lineNo;

function scan(job: ScanJob, report: (snap: Snapshot) => void): void {
	const startedAt = performance.now();
	const hardStop = startedAt + job.deadlineMs + 5_000;
	const re = new RegExp(job.source, job.flags);
	const roleFilter = job.roleFilter;
	const sinceMs = job.sinceMs;
	const untilMs = job.untilMs ?? Number.POSITIVE_INFINITY;
	const maxTsMs = job.maxTsMs ?? Number.POSITIVE_INFINITY;
	const hasTemporalBound = sinceMs > 0 || Number.isFinite(untilMs) || Number.isFinite(maxTsMs);
	const limit = job.limit;
	const contextChars = job.contextChars;
	const files = collectJsonlFiles(job.sessionsDir, job.includeHelpers);
	const kept: MatchRow[] = [];
	let totalMatches = 0;
	let skippedFiles = 0;
	let skippedLines = 0;
	let filesDone = 0;
	let dirty = false;
	let lastReport = startedAt;
	const snapshot = (done: boolean): Snapshot => ({ files: files.length, filesDone, kept, totalMatches, skippedFiles, skippedLines, done });
	const tick = () => {
		const now = performance.now();
		if (now > hardStop) process.exit(3);
		if (dirty && now - lastReport >= SNAPSHOT_MS) {
			report(snapshot(false));
			lastReport = now;
			dirty = false;
		}
	};
	report(snapshot(false));
	const buf = Buffer.allocUnsafe(CHUNK_BYTES);

	for (const file of files) {
		const relPath = path.relative(job.sessionsDir, file);
		let lineNo = 0;
		const onLine = (raw: string) => {
			lineNo++;
			tick();
			if (!raw) return;
			if (raw.length > MAX_LINE_CHARS) {
				skippedLines++;
				dirty = true;
				return;
			}
			const rec = parseRecord(raw);
			if (!rec) return;
			if (roleFilter !== "all" && rec.role !== roleFilter) return;
			if (hasTemporalBound && rec.tsMs <= 0) return;
			if (sinceMs > 0 && rec.tsMs < sinceMs) return;
			if (Number.isFinite(untilMs) && rec.tsMs > untilMs) return;
			if (Number.isFinite(maxTsMs) && rec.tsMs >= maxTsMs) return;
			if (ENV_SECRET_HINT_RE.test(rec.text)) rec.text = rec.text.replace(ENV_SECRET_RE, "$1$2[redacted]");
			rec.text = rec.text.replace(SECRET_RE, "[redacted]");
			const m = re.exec(rec.text);
			if (!m) return;
			totalMatches++;
			dirty = true;
			const key = { tsMs: rec.tsMs, lineNo };
			let worst = -1;
			if (kept.length >= limit) {
				worst = 0;
				for (let k = 1; k < kept.length; k++) if (newer(kept[k], kept[worst]) < 0) worst = k;
				if (newer(key, kept[worst]) <= 0) return;
			}
			const row: MatchRow = {
				tsMs: rec.tsMs,
				ts: rec.ts || "unknown-time",
				speaker: rec.speaker,
				relPath,
				lineNo,
				snippet: makeSnippet(rec.text, m.index, m[0].length, contextChars),
			};
			if (formatRow(row).length >= MAX_OUTPUT_CHARS) {
				row.ts = "";
				row.speaker = "";
				row.snippet = "";
				row.oversized = true;
			}
			if (worst >= 0) kept[worst] = row;
			else kept.push(row);
		};
		let fd = -1;
		try {
			fd = fs.openSync(file, "r");
			const decoder = new TextDecoder("utf-8", { ignoreBOM: true });
			let rest = "";
			let skipLF = false;
			for (;;) {
				const n = fs.readSync(fd, buf, 0, CHUNK_BYTES, null);
				const text = n > 0 ? decoder.decode(buf.subarray(0, n), { stream: true }) : decoder.decode();
				let i = 0;
				if (skipLF && text.length > 0) {
					if (text.charCodeAt(0) === 10) i = 1;
					skipLF = false;
				}
				while (i < text.length) {
					LINE_BREAK_RE.lastIndex = i;
					const br = LINE_BREAK_RE.exec(text);
					if (!br) {
						rest += text.slice(i);
						break;
					}
					const j = br.index;
					const line = rest.length > 0 ? rest + text.slice(i, j) : text.slice(i, j);
					rest = "";
					onLine(line);
					if (br[0] === "\r") {
						if (j + 1 < text.length) {
							i = text.charCodeAt(j + 1) === 10 ? j + 2 : j + 1;
						} else {
							skipLF = true;
							i = j + 1;
						}
					} else {
						i = j + 1;
					}
				}
				tick();
				if (n === 0) break;
			}
			if (rest.length > 0) onLine(rest);
		} catch {
			skippedFiles++;
		} finally {
			if (fd >= 0) fs.closeSync(fd);
		}
		filesDone++;
		dirty = true;
		tick();
	}

	report(snapshot(true));
}

async function runChild(): Promise<void> {
	let input = "";
	process.stdin.setEncoding("utf8");
	for await (const chunk of process.stdin) input += chunk;
	const job = JSON.parse(input) as ScanJob;
	scan(job, (snap) => {
		process.stdout.write(`${JSON.stringify(snap)}\n`);
	});
}

if (import.meta.main && process.env.GREPMEM_CHILD === "1") void runChild();

function runScan(job: ScanJob, signal?: AbortSignal): Promise<ScanRun> {
	return new Promise((resolve) => {
		let snap: Snapshot | undefined;
		let stopped: ScanRun["stopped"];
		let settled = false;
		let pending = "";
		const child = spawn(process.execPath, [fileURLToPath(import.meta.url)], {
			env: { HOME: process.env.HOME ?? "/", BUN_BE_BUN: "1", GREPMEM_CHILD: "1" },
			cwd: "/",
			stdio: ["pipe", "pipe", "ignore"],
		});
		const stop = (why: "timeout" | "aborted") => {
			if (settled || stopped || snap?.done) return;
			stopped = why;
			child.kill("SIGKILL");
		};
		const onAbort = () => stop("aborted");
		const timer = setTimeout(() => stop("timeout"), job.deadlineMs);
		const finish = (error?: string) => {
			if (settled) return;
			settled = true;
			clearTimeout(timer);
			signal?.removeEventListener("abort", onAbort);
			resolve({ snap, stopped, error });
		};
		signal?.addEventListener("abort", onAbort, { once: true });
		child.stdout?.setEncoding("utf8");
		child.stdout?.on("data", (chunk: string) => {
			pending += chunk;
			const end = pending.lastIndexOf("\n");
			if (end < 0) return;
			const start = pending.lastIndexOf("\n", end - 1) + 1;
			try {
				snap = JSON.parse(pending.slice(start, end)) as Snapshot;
			} catch {}
			pending = pending.slice(end + 1);
		});
		child.on("error", (err) => {
			child.kill("SIGKILL");
			finish(err.message);
		});
		child.on("close", (code, sig) => finish(snap?.done || stopped ? undefined : `search process exited (${sig ?? code})`));
		child.stdin?.on("error", () => {});
		child.stdin?.end(JSON.stringify(job));
		if (signal?.aborted) stop("aborted");
	});
}

export default function grepmem(pi: ExtensionAPI): void {
	const z = pi.zod;

	pi.registerTool({
		name: "grepmem",
		label: "Grep raw history",
		description:
			"Read-only search over raw bot session JSONL transcripts: literal substring by default, a JavaScript regex when regex is true. Returns timestamped, speaker-labelled snippets with session path and line number. Stops after 30s and returns partial results.",
		parameters: z.object({
			pattern: z.string().describe("Text to search for; a literal substring unless regex is true"),
			regex: z.boolean().optional().describe("Treat pattern as a regex (default false: literal substring)"),
			case_sensitive: z.boolean().optional().describe("Case-sensitive matching (default false)"),
			role: z.enum(["all", "user", "assistant", "toolResult", "custom"]).optional().describe("Filter by message role (default all)"),
			since: z.string().optional().describe("ISO timestamp lower bound (inclusive)"),
			until: z.string().optional().describe("ISO timestamp upper bound (inclusive)"),
			include_helpers: z.boolean().optional().describe("Also search helper sub-transcripts (default false)"),
			limit: z.number().int().min(1).max(MAX_LIMIT).optional().describe("Maximum matches to return (default 20, max 50)"),
			context_chars: z.number().int().min(40).max(MAX_CONTEXT).optional().describe("Snippet width in characters (default 240, max 600)"),
			bot: z.string().optional().describe("Another bot's name; only works where cross-bot search is enabled"),
		}),
		async execute(_toolCallId, params, signal) {
			const dirOrErr = resolveSessionsDir(params.bot);
			if (typeof dirOrErr !== "string") {
				return { content: [{ type: "text" as const, text: dirOrErr.error }] };
			}
			const sessionsDir = path.resolve(dirOrErr);

			const source = params.regex === true ? params.pattern : params.pattern.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
			const flags = params.case_sensitive ? "" : "i";
			try {
				new RegExp(source, flags);
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


			if (signal?.aborted) {
				return { content: [{ type: "text" as const, text: "GrepMem search was aborted before it started." }] };
			}

			const run = await runScan(
				{
					sessionsDir,
					includeHelpers: params.include_helpers ?? false,
					source,
					flags,
					roleFilter: params.role ?? "all",
					sinceMs,
					untilMs: Number.isFinite(untilMs) ? untilMs : null,
					maxTsMs: null,
					limit: Math.min(MAX_LIMIT, Math.max(1, params.limit ?? DEFAULT_LIMIT)),
					contextChars: Math.min(MAX_CONTEXT, Math.max(40, params.context_chars ?? DEFAULT_CONTEXT)),
					deadlineMs: DEADLINE_MS,
				},
				signal,
			);

			const reason =
				run.stopped === "timeout"
					? `timed out after ${DEADLINE_MS / 1000}s and was stopped`
					: run.stopped === "aborted"
						? "was aborted"
						: `stopped early: ${run.error ?? "unknown error"}`;
			const snap = run.snap;
			if (!snap) {
				return { content: [{ type: "text" as const, text: `GrepMem search ${reason} before scanning any files.` }] };
			}

			const partial = !snap.done;
			const fileCount = partial ? `${snap.filesDone} of ${snap.files}` : `${snap.files}`;
			const head: string[] = partial ? [`Partial results: search ${reason} after scanning ${snap.filesDone} of ${snap.files} file(s).`] : [];
			const selected = snap.kept.sort((a, b) => newer(b, a));
			const skipNote =
				snap.skippedFiles || snap.skippedLines
					? ` (skipped ${snap.skippedFiles} unreadable file(s), ${snap.skippedLines} oversized line(s))`
					: "";

			if (selected.length === 0) {
				return {
					content: [
						{ type: "text" as const, text: [...head, `No matches for ${JSON.stringify(params.pattern)} in ${fileCount} session file(s).${skipNote}`].join("\n") },
					],
				};
			}

			const out: string[] = [
				...head,
				`Matches: ${selected.length} shown of ${snap.totalMatches} total across ${fileCount} file(s)${skipNote} (newest first):`,
			];
			let chars = out.reduce((n, line) => n + line.length, 0) + out.length - 1;
			for (const row of selected) {
				const formatted = row.oversized ? "" : formatRow(row);
				if (row.oversized || chars + formatted.length + 1 > MAX_OUTPUT_CHARS) {
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
