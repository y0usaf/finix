''
  #!/usr/bin/env bun
  import { readFileSync, writeFileSync, existsSync, mkdirSync } from "fs";
  import { join } from "path";
  import { exec } from "child_process";

  const LOGS_DIR = join(process.env.HOME || "/tmp", ".claude", "logs");
  const SOUNDS_DIR = join(process.env.HOME || "/tmp", ".claude");

  // Ensure logs directory exists
  if (!existsSync(LOGS_DIR)) {
    mkdirSync(LOGS_DIR, { recursive: true });
  }

  export function hasFlag(flag: string): boolean {
    return process.argv.includes(flag);
  }

  export function readStdin(): Promise<string> {
    return new Promise((resolve, reject) => {
      let input = "";
      process.stdin.setEncoding("utf8");

      process.stdin.on("data", (chunk) => {
        input += chunk;
      });

      process.stdin.on("end", () => {
        resolve(input);
      });

      process.stdin.on("error", (err) => {
        reject(err);
      });

      // Timeout after 5 seconds to prevent hanging
      setTimeout(() => {
        if (input) {
          resolve(input);
        } else {
          reject(new Error("Stdin read timeout"));
        }
      }, 5000);
    });
  }

  export function parseJson<T = Record<string, unknown>>(input: string): T | null {
    try {
      return JSON.parse(input) as T;
    } catch {
      return null;
    }
  }

  export function appendToLog(logFileName: string, data: Record<string, unknown>): void {
    const logFile = join(LOGS_DIR, logFileName);
    let logs: Record<string, unknown>[] = [];

    if (existsSync(logFile)) {
      try {
        const content = readFileSync(logFile, "utf8");
        logs = JSON.parse(content);
        if (!Array.isArray(logs)) logs = [];
      } catch {
        logs = [];
      }
    }

    logs.push({
      timestamp: new Date().toISOString(),
      ...data,
    });

    // Keep only last 1000 entries to prevent unbounded growth
    if (logs.length > 1000) {
      logs = logs.slice(-1000);
    }

    writeFileSync(logFile, JSON.stringify(logs, null, 2));
  }

  export function playSound(soundFileName: string, volume = 1.0): Promise<void> {
    return new Promise((resolve) => {
      // Skip sounds in headless mode
      if (process.env.CLAUDE_CODE_HEADLESS === "1") {
        resolve();
        return;
      }

      const soundFile = join(SOUNDS_DIR, soundFileName);

      if (!existsSync(soundFile)) {
        console.error(`Sound file not found: ''${soundFile}`);
        resolve();
        return;
      }

      // Linux - try pipewire first, then pulseaudio, then alsa
      const pulseVolume = Math.round(volume * 65536);
      const cmd = `pw-play --volume=''${volume} "''${soundFile}" 2>/dev/null || paplay --volume=''${pulseVolume} "''${soundFile}" 2>/dev/null || aplay -q "''${soundFile}" 2>/dev/null`;

      exec(cmd, (err) => {
        if (err) {
          console.error("Error playing sound:", err.message);
        }
        resolve();
      });
    });
  }

  export interface HookData {
    stop_hook_active?: boolean;
    transcript_path?: string;
    [key: string]: unknown;
  }

  export async function runHook(
    logFileName: string,
    onData: (data: HookData) => Promise<void>
  ): Promise<void> {
    try {
      const input = await readStdin();
      const data = parseJson<HookData>(input);

      if (!data) {
        console.error("Failed to parse input JSON");
        process.exit(1);
      }

      appendToLog(logFileName, data);
      await onData(data);
      process.exit(0);
    } catch (error) {
      console.error("Hook error:", error);
      process.exit(1);
    }
  }
''
