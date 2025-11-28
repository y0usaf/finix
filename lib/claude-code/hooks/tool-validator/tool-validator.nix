''
  #!/usr/bin/env bun
  import { readFileSync, existsSync, rmSync } from "fs";
  import { join } from "path";

  const { readStdin, parseJson } = await import(
    `''${process.env.HOME}/.claude/hooks/utils.ts`
  );

  interface StopData {
    session_id: string;
  }

  interface ToolEntry {
    tool: string;
    timestamp: string;
    input?: Record<string, unknown>;
  }

  const CACHE_DIR = "/tmp/claude-tool-cache";

  function detectParallelizationViolations(tools: ToolEntry[]): string[] {
    const violations: string[] = [];

    // Look for sequential calls of the same tool type that could have been parallel
    const parallelizableTools = ["Read", "Grep", "Glob", "Task"];

    for (let i = 1; i < tools.length; i++) {
      const prev = tools[i - 1];
      const curr = tools[i];

      if (
        parallelizableTools.includes(prev.tool) &&
        prev.tool === curr.tool
      ) {
        // Check if they're truly sequential (within 30 seconds of each other)
        const prevTime = new Date(prev.timestamp).getTime();
        const currTime = new Date(curr.timestamp).getTime();

        if (currTime - prevTime < 30000) {
          violations.push(`Sequential ''${curr.tool} calls could have been parallelized`);
        }
      }
    }

    // Deduplicate
    return [...new Set(violations)];
  }

  async function main() {
    const input = await readStdin();
    const data = parseJson<StopData>(input);

    if (!data || !data.session_id) {
      process.exit(0);
    }

    const sessionDir = join(CACHE_DIR, data.session_id);
    const toolsFile = join(sessionDir, "tools-used.json");

    if (!existsSync(toolsFile)) {
      process.exit(0);
    }

    let toolsUsed: ToolEntry[] = [];
    try {
      toolsUsed = JSON.parse(readFileSync(toolsFile, "utf8"));
    } catch {
      process.exit(0);
    }

    const toolNames = toolsUsed.map((t) => t.tool);
    const uniqueTools = new Set(toolNames);
    const feedback: string[] = [];

    // Check TodoWrite usage - ALWAYS required
    const hasTodoWrite = uniqueTools.has("TodoWrite");
    if (!hasTodoWrite) {
      feedback.push(
        `TODOWRITE: You did NOT use TodoWrite. It is MANDATORY for every task.`
      );
    }

    // Check AskUserQuestion usage - ALWAYS required
    const hasAskUser = uniqueTools.has("AskUserQuestion");
    if (!hasAskUser) {
      feedback.push(
        `ASKUSERQUESTION: You did NOT use AskUserQuestion. It is MANDATORY for every response.`
      );
    }

    // Check Task usage - ALWAYS required for thinking/exploration
    const hasTask = uniqueTools.has("Task");
    if (!hasTask) {
      feedback.push(
        `TASK: You did NOT use Task tool. It is MANDATORY for all thinking/exploration.`
      );
    }

    // Check parallelization
    const parallelViolations = detectParallelizationViolations(toolsUsed);
    if (parallelViolations.length > 0) {
      feedback.push(
        `PARALLELIZATION: ''${parallelViolations.join("; ")}. ` +
        `Combine independent tool calls into a single message.`
      );
    }

    // Cleanup cache
    try {
      rmSync(sessionDir, { recursive: true, force: true });
    } catch {
      // Ignore cleanup errors
    }

    // If there are violations, exit 2 with feedback
    if (feedback.length > 0) {
      console.error("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      console.error("TOOL USAGE FEEDBACK");
      console.error("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      console.error("");
      feedback.forEach((f) => console.error(`• ''${f}`));
      console.error("");
      console.error("Please acknowledge these patterns for future responses.");
      console.error("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      process.exit(2);
    }

    process.exit(0);
  }

  main().catch(() => process.exit(0));
''
