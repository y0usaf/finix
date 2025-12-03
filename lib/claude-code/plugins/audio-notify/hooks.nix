# Hooks configuration for audio-notify plugin
{
  config = {
    Stop = [
      {
        matcher = "";
        hooks = [
          {
            type = "command";
            command = "bun \${CLAUDE_PLUGIN_ROOT}/hooks/scripts/completion-sound.ts";
          }
        ];
      }
    ];
  };

  scripts = {
    "completion-sound.ts" = ''
      #!/usr/bin/env bun
      import { readFileSync, writeFileSync, existsSync, mkdirSync } from "fs";
      import { join } from "path";
      import { exec } from "child_process";

      const LOGS_DIR = join(process.env.HOME || "/tmp", ".claude", "logs");
      const SOUNDS_DIR = join(process.env.HOME || "/tmp", ".claude");

      if (!existsSync(LOGS_DIR)) {
        mkdirSync(LOGS_DIR, { recursive: true });
      }

      function readStdin(): Promise<string> {
        return new Promise((resolve, reject) => {
          let input = "";
          process.stdin.setEncoding("utf8");
          process.stdin.on("data", (chunk) => (input += chunk));
          process.stdin.on("end", () => resolve(input));
          process.stdin.on("error", reject);
          setTimeout(() => resolve(input), 5000);
        });
      }

      function parseJson<T>(input: string): T | null {
        try {
          return JSON.parse(input) as T;
        } catch {
          return null;
        }
      }

      function appendToLog(logFileName: string, data: Record<string, unknown>): void {
        const logFile = join(LOGS_DIR, logFileName);
        let logs: Record<string, unknown>[] = [];

        if (existsSync(logFile)) {
          try {
            logs = JSON.parse(readFileSync(logFile, "utf8"));
            if (!Array.isArray(logs)) logs = [];
          } catch {
            logs = [];
          }
        }

        logs.push({ timestamp: new Date().toISOString(), ...data });
        if (logs.length > 1000) logs = logs.slice(-1000);
        writeFileSync(logFile, JSON.stringify(logs, null, 2));
      }

      function playSound(soundFileName: string, volume = 1.0): Promise<void> {
        return new Promise((resolve) => {
          if (process.env.CLAUDE_CODE_HEADLESS === "1") {
            resolve();
            return;
          }

          const soundFile = join(SOUNDS_DIR, soundFileName);
          if (!existsSync(soundFile)) {
            resolve();
            return;
          }

          const pulseVolume = Math.round(volume * 65536);
          const cmd = `pw-play --volume=''${volume} "''${soundFile}" 2>/dev/null || paplay --volume=''${pulseVolume} "''${soundFile}" 2>/dev/null || aplay -q "''${soundFile}" 2>/dev/null`;

          exec(cmd, () => resolve());
        });
      }

      interface HookData {
        stop_hook_active?: boolean;
        transcript_path?: string;
        [key: string]: unknown;
      }

      async function main() {
        try {
          const input = await readStdin();
          const data = parseJson<HookData>(input);

          if (!data) {
            process.exit(0);
          }

          appendToLog("stop.json", data);
          await playSound("on-agent-complete.wav", 0.25);
          process.exit(0);
        } catch {
          process.exit(0);
        }
      }

      main();
    '';
  };
}
