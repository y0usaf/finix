''
  #!/usr/bin/env bun
  import { writeFileSync, existsSync, mkdirSync, readFileSync } from "fs";
  import { join } from "path";

  const { readStdin, parseJson } = await import(
    `''${process.env.HOME}/.claude/hooks/utils.ts`
  );

  interface ToolUseData {
    tool_name: string;
    tool_input?: Record<string, unknown>;
    session_id: string;
  }

  const CACHE_DIR = "/tmp/claude-tool-cache";

  async function main() {
    const input = await readStdin();
    const data = parseJson<ToolUseData>(input);

    if (!data || !data.tool_name || !data.session_id) {
      process.exit(0);
    }

    const sessionDir = join(CACHE_DIR, data.session_id);
    if (!existsSync(sessionDir)) {
      mkdirSync(sessionDir, { recursive: true });
    }

    const toolsFile = join(sessionDir, "tools-used.json");
    let toolsUsed: { tool: string; timestamp: string; input?: Record<string, unknown> }[] = [];

    if (existsSync(toolsFile)) {
      try {
        toolsUsed = JSON.parse(readFileSync(toolsFile, "utf8"));
      } catch {
        toolsUsed = [];
      }
    }

    toolsUsed.push({
      tool: data.tool_name,
      timestamp: new Date().toISOString(),
      input: data.tool_input,
    });

    writeFileSync(toolsFile, JSON.stringify(toolsUsed, null, 2));
    process.exit(0);
  }

  main().catch(() => process.exit(0));
''
