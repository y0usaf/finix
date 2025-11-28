''
  #!/usr/bin/env bun
  import { readFileSync, writeFileSync, existsSync } from "fs";
  import { join } from "path";

  const { runHook, playSound, hasFlag } = await import(
    `''${process.env.HOME}/.claude/hooks/utils.ts`
  );

  const LOGS_DIR = join(process.env.HOME || "/tmp", ".claude", "logs");

  function processTranscript(transcriptPath: string): void {
    if (!existsSync(transcriptPath)) return;

    try {
      const content = readFileSync(transcriptPath, "utf8");
      const chatData = content
        .split("\n")
        .filter((line) => line.trim())
        .map((line) => {
          try {
            return JSON.parse(line);
          } catch {
            return null;
          }
        })
        .filter(Boolean);

      writeFileSync(join(LOGS_DIR, "chat.json"), JSON.stringify(chatData, null, 2));
    } catch (e) {
      console.error("Error processing transcript:", e);
    }
  }

  runHook("stop.json", async (data: { stop_hook_active?: boolean; transcript_path?: string }) => {
    await playSound("on-agent-complete.wav");

    if (hasFlag("--chat") && data.transcript_path) {
      processTranscript(data.transcript_path);
    }
  });
''
