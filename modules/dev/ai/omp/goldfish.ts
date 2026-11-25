import { spawnSync } from "node:child_process";
import { randomBytes } from "node:crypto";
import { existsSync, mkdirSync, rmSync, statSync, writeFileSync } from "node:fs";
import { dirname, isAbsolute, join, resolve } from "node:path";
import {
	type AgentDefinition,
	type ExtensionAPI,
	type ExtensionContext,
	runSubprocess,
	settings,
} from "@oh-my-pi/pi-coding-agent";

export type GoldfishKind = "design" | "code" | "repo";
export type GoldfishVerdict = "SHIP" | "FIX_FIRST" | "RETHINK";

export interface GoldfishFinding {
	severity: "blocking" | "note";
	file: string;
	line: number;
	issue: string;
	scenario: string;
	fix: string;
}

export interface GoldfishCheckOutput {
	command: string;
	code: number;
	output: string;
}

export interface GoldfishAuditOptions {
	kind: GoldfishKind;
	targets: string[];
	base_ref?: string;
	check?: string;
	check_output?: GoldfishCheckOutput;
}

export interface GoldfishAuditResult {
	verdict: GoldfishVerdict;
	summary: string;
	findings: GoldfishFinding[];
	model: string;
	raw: string;
}

const MAX_DIFF_BYTES = 200000;
const MAX_CHECK_CHARS = 40000;
const CHECK_TIMEOUT_MS = 300000;

const OUTPUT_SCHEMA = {
	type: "object",
	additionalProperties: false,
	required: ["verdict", "summary", "findings"],
	properties: {
		verdict: { type: "string", enum: ["SHIP", "FIX_FIRST", "RETHINK"] },
		summary: { type: "string" },
		findings: {
			type: "array",
			items: {
				type: "object",
				additionalProperties: false,
				required: ["severity", "file", "line", "issue", "scenario", "fix"],
				properties: {
					severity: { type: "string", enum: ["blocking", "note"] },
					file: { type: "string" },
					line: { type: "integer", minimum: 0 },
					issue: { type: "string" },
					scenario: { type: "string" },
					fix: { type: "string" },
				},
			},
		},
	},
};

const TOOL_SCHEMA = {
	type: "object",
	additionalProperties: false,
	required: ["kind", "targets"],
	properties: {
		kind: { type: "string", enum: ["design", "code", "repo"] },
		targets: { type: "array", items: { type: "string" }, minItems: 1 },
		base_ref: { type: "string" },
		check: { type: "string" },
	},
};

const DEFAULT_PROMPT = [
	"You are Goldfish, a blind, zero-history adversarial auditor. You have no conversation history and no allegiance to the author.",
	"",
	"Rules:",
	"- Inspect only the provided target paths and snapshot files using `read`, `grep`, and `find`.",
	"- Default verdict is `SHIP`. Returning `SHIP` with zero blocking findings when the artifact is sound is a successful audit. Never invent defects to justify running.",
	"- Use `FIX_FIRST` only when there is at least one concrete `blocking` finding with an exact `file:line`, a reproducible failure scenario (logic bug, race condition, security flaw, resource leak, broken contract, or wrong runtime behavior), and a minimal fix.",
	"- Style nits, hypothetical refactors, unverified speculation, and missing tests (unless a test is broken or explicitly required by the target contract) MUST NOT trigger `FIX_FIRST`. Either omit them or record them with `severity: \"note\"`.",
	"- Reserve `RETHINK` for fundamental architectural or design mismatches where local patches cannot fix the problem.",
	"- Verify every file path and line number directly against the files before reporting.",
	"",
	"Return a JSON object strictly matching:",
	"{",
	"  \"verdict\": \"SHIP\" | \"FIX_FIRST\" | \"RETHINK\",",
	"  \"summary\": string,",
	"  \"findings\": [",
	"    {",
	"      \"severity\": \"blocking\" | \"note\",",
	"      \"file\": string,",
	"      \"line\": number,",
	"      \"issue\": string,",
	"      \"scenario\": string,",
	"      \"fix\": string",
	"    }",
	"  ]",
	"}",
].join("\n");

function makeSnapDir(): string {
	const rand = randomBytes(6).toString("hex");
	const dir = process.env.XDG_RUNTIME_DIR
		? join(process.env.XDG_RUNTIME_DIR, "agent", `goldfish-${rand}`)
		: join("/tmp", `goldfish-${process.getuid?.() ?? 0}-${rand}`);
	mkdirSync(dir, { recursive: true, mode: 0o700 });
	return dir;
}

function loadGoldfishAgent(): AgentDefinition {
	return {
		name: "goldfish",
		description: "Blind zero-history adversarial auditor",
		systemPrompt: DEFAULT_PROMPT,
		tools: ["read", "grep", "find"],
		model: ["@advisor"],
		thinkingLevel: "auto",
		structured: true,
		readSummarize: false,
		advisor: false,
		source: "user",
	};
}

function capText(text: string, max: number): string {
	if (text.length <= max) return text;
	return `${text.slice(0, max)}\n...[truncated]`;
}

function tailText(text: string, max: number): string {
	if (text.length <= max) return text;
	return `...[truncated]\n${text.slice(-max)}`;
}

function runGit(cwd: string, args: string[]): string {
	const res = spawnSync("git", ["-C", cwd, ...args], {
		encoding: "utf8",
		timeout: 15000,
		maxBuffer: 4 * 1024 * 1024,
	});
	if (res.status !== 0) return "";
	return (res.stdout ?? "").trimEnd();
}

function parseJsonPayload(raw: string): unknown {
	const trimmed = raw.trim();
	if (!trimmed) return undefined;
	try {
		return JSON.parse(trimmed);
	} catch {}
	const fenced = /```(?:json)?\s*([\s\S]*?)```/.exec(trimmed);
	if (fenced) {
		try {
			return JSON.parse(fenced[1].trim());
		} catch {}
	}
	const start = trimmed.indexOf("{");
	const end = trimmed.lastIndexOf("}");
	if (start >= 0 && end > start) {
		try {
			return JSON.parse(trimmed.slice(start, end + 1));
		} catch {}
	}
	return undefined;
}

function normalizeResult(data: unknown, model: string, raw: string): GoldfishAuditResult | undefined {
	if (!data || typeof data !== "object") return undefined;
	const rec = data as Record<string, unknown>;
	const rawVerdict = rec.verdict;
	if (rawVerdict !== "SHIP" && rawVerdict !== "FIX_FIRST" && rawVerdict !== "RETHINK") return undefined;
	const summary = typeof rec.summary === "string" ? rec.summary.trim() : "";
	const rawFindings = Array.isArray(rec.findings) ? rec.findings : [];
	const findings: GoldfishFinding[] = rawFindings
		.filter((item): item is Record<string, unknown> => Boolean(item) && typeof item === "object")
		.map(item => ({
			severity: item.severity === "blocking" ? "blocking" : "note",
			file: typeof item.file === "string" ? item.file.trim() : "",
			line: Number.isFinite(Number(item.line)) ? Math.max(0, Math.floor(Number(item.line))) : 0,
			issue: typeof item.issue === "string" ? item.issue.trim() : "",
			scenario: typeof item.scenario === "string" ? item.scenario.trim() : "",
			fix: typeof item.fix === "string" ? item.fix.trim() : "",
		}));

	let verdict: GoldfishVerdict = rawVerdict;
	if (verdict === "FIX_FIRST") {
		const realBlockers = findings.filter(f => f.severity === "blocking" && f.file.length > 0 && f.scenario.length > 0);
		if (realBlockers.length === 0) verdict = "SHIP";
	}

	return { verdict, summary, findings, model, raw };
}

export function formatGoldfishReport(result: GoldfishAuditResult): string {
	const lines: string[] = [];
	lines.push(`GOLDFISH VERDICT: ${result.verdict}${result.model ? ` (${result.model})` : ""}`);
	if (result.summary) lines.push(`Summary: ${result.summary}`);
	const blocking = result.findings.filter(f => f.severity === "blocking");
	const notes = result.findings.filter(f => f.severity !== "blocking");
	if (blocking.length > 0) {
		lines.push("", "Blocking findings:");
		for (const f of blocking) {
			lines.push(`- ${f.file}:${f.line} — ${f.issue}`);
			if (f.scenario) lines.push(`  Scenario: ${f.scenario}`);
			if (f.fix) lines.push(`  Fix: ${f.fix}`);
		}
	}
	if (notes.length > 0) {
		lines.push("", "Notes:");
		for (const f of notes) {
			lines.push(`- ${f.file}:${f.line} — ${f.issue}`);
		}
	}
	return lines.join("\n");
}

export async function runGoldfishAudit(
	opts: GoldfishAuditOptions,
	ctx: ExtensionContext,
	signal?: AbortSignal,
): Promise<GoldfishAuditResult> {
	if (!Array.isArray(opts.targets) || opts.targets.length === 0) {
		throw new Error("goldfish requires at least one target path");
	}
	const baseRef = opts.base_ref?.trim();
	if (baseRef && baseRef.startsWith("-")) {
		throw new Error("goldfish base_ref must not start with '-'");
	}

	const resolvedTargets: string[] = [];
	const targetDirs = new Set<string>();
	for (const rawTarget of opts.targets) {
		const target = isAbsolute(rawTarget) ? resolve(rawTarget) : resolve(ctx.cwd, rawTarget);
		if (!existsSync(target)) {
			throw new Error(`goldfish target does not exist: ${rawTarget}`);
		}
		resolvedTargets.push(target);
		targetDirs.add(statSync(target).isDirectory() ? target : dirname(target));
	}

	const snapDir = makeSnapDir();
	try {
		const snapFiles: string[] = [];
		const repoRoots = new Set<string>();
		for (const dir of targetDirs) {
			const root = runGit(dir, ["rev-parse", "--show-toplevel"]);
			if (root) repoRoots.add(root);
		}

		let repoIdx = 0;
		for (const root of repoRoots) {
			const status = runGit(root, ["status", "--short", "--branch"]);
			if (status) {
				const p = join(snapDir, `git-status-${repoIdx}.txt`);
				writeFileSync(p, `repo: ${root}\n${status}\n`, "utf8");
				snapFiles.push(p);
			}
			const diffArgs = baseRef ? ["diff", "--stat", baseRef] : ["diff", "--stat", "HEAD"];
			const stat = runGit(root, diffArgs) || runGit(root, ["diff", "--stat"]);
			if (stat) {
				const p = join(snapDir, `git-diff-stat-${repoIdx}.txt`);
				writeFileSync(p, `repo: ${root}\n${stat}\n`, "utf8");
				snapFiles.push(p);
			}
			const patchArgs = baseRef ? ["diff", baseRef] : ["diff", "HEAD"];
			const patch = runGit(root, patchArgs) || runGit(root, ["diff"]);
			if (patch) {
				const p = join(snapDir, `git-diff-${repoIdx}.patch`);
				writeFileSync(p, `repo: ${root}\n${capText(patch, MAX_DIFF_BYTES)}\n`, "utf8");
				snapFiles.push(p);
			}
			repoIdx += 1;
		}

		let checkInfo: GoldfishCheckOutput | undefined = opts.check_output;
		if (!checkInfo && opts.check?.trim()) {
			const command = opts.check.trim();
			const res = spawnSync("sh", ["-c", command], {
				cwd: ctx.cwd,
				encoding: "utf8",
				timeout: CHECK_TIMEOUT_MS,
				maxBuffer: 4 * 1024 * 1024,
			});
			const combined = `${res.stdout ?? ""}\n${res.stderr ?? ""}`.trim();
			checkInfo = {
				command,
				code: res.status ?? 1,
				output: tailText(combined, MAX_CHECK_CHARS),
			};
		}

		let checkFile: string | undefined;
		if (checkInfo) {
			checkFile = join(snapDir, "check.txt");
			writeFileSync(
				checkFile,
				`command: ${checkInfo.command}\nexit_code: ${checkInfo.code}\n\n${tailText(checkInfo.output, MAX_CHECK_CHARS)}\n`,
				"utf8",
			);
			snapFiles.push(checkFile);
		}

		const promptLines: string[] = [
			`Audit kind: ${opts.kind}`,
			"Targets:",
			...resolvedTargets.map(t => `- ${t}`),
		];
		if (snapFiles.length > 0) {
			promptLines.push("Snapshots:", ...snapFiles.map(s => `- ${s}`));
		}
		if (checkInfo && checkFile) {
			promptLines.push(`Check: ${checkInfo.command} (exit ${checkInfo.code}, output in ${checkFile})`);
		}

		const agent = loadGoldfishAgent();
		const result = await runSubprocess({
			cwd: ctx.cwd,
			additionalDirectories: [snapDir, ...targetDirs],
			agent,
			task: promptLines.join("\n"),
			index: 0,
			id: `goldfish-${randomBytes(4).toString("hex")}`,
			structured: true,
			outputSchema: OUTPUT_SCHEMA,
			outputSchemaMode: "strict",
			outputSchemaSource: "caller",
			outputSchemaOverridesAgent: true,
			restrictToolNames: true,
			enableMCP: false,
			enableLsp: false,
			enableIrc: false,
			noContextFiles: true,
			sessionFile: null,
			persistArtifacts: false,
			modelRegistry: ctx.modelRegistry,
			settings: settings.overlay(
				{
					"grep.enabled": true,
					"glob.enabled": true,
					"find.enabled": "on",
				},
				{ derived: true },
			),
			signal,
		});

		const candidate =
			result.structuredOutput?.status === "valid"
				? result.structuredOutput.data
				: result.structuredOutput?.data ?? parseJsonPayload(result.output);
		const normalized = normalizeResult(candidate, result.resolvedModel ?? "", result.output);
		if (!normalized) {
			const detail = result.structuredOutput?.error || result.stderr || result.output.slice(0, 400) || "invalid structured output";
			throw new Error(`Goldfish audit failed (exit ${result.exitCode}): ${detail}`);
		}
		return normalized;
	} finally {
		rmSync(snapDir, { recursive: true, force: true });
	}
}

export default function goldfish(pi: ExtensionAPI): void {
	pi.on("session_start", (_event, ctx) => {
		if (ctx.agent?.name === "goldfish") return;
		pi.registerTool({
			name: "goldfish",
			label: "Goldfish",
			description: "Run a blind, zero-history, read-only adversarial audit on specified targets.",
			parameters: TOOL_SCHEMA,
			async execute(_toolCallId, params, signal, _onUpdate, toolCtx) {
				const input = params as unknown as GoldfishAuditOptions;
				const result = await runGoldfishAudit(
					{
						kind: input.kind,
						targets: input.targets,
						base_ref: input.base_ref,
						check: input.check,
					},
					toolCtx,
					signal,
				);
				return {
					content: [{ type: "text", text: formatGoldfishReport(result) }],
					details: result,
				};
			},
		});
	});
}
