{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  piPkg = flakeInputs."pi-mono".packages."${system}".default;
  piAgentsPkg = flakeInputs."pi-agents".packages."${system}".default;

  # -------------------------------------------------------------------------
  # Full system prompt override.
  # Written to ~/.pi/agent/custom-system-prompt.md, read by extension at runtime.
  # Reference default written to ~/.pi/agent/system-prompt.md.
  # Extension returns custom string as systemPrompt.
  # -------------------------------------------------------------------------
  customPiSystemPrompt = ''
    You are an expert coding assistant operating inside pi, a coding agent harness. You help users by reading files, executing commands, editing code, and writing new files.

    Available tools:
    ''${toolsList}

    In addition to the tools above, you may have access to other custom tools depending on the project.

    Guidelines:
    ''${guidelines}

    Pi documentation (read only when the user asks about pi itself, its SDK, extensions, themes, skills, or TUI):
    - Main documentation: ''${readmePath}
    - Additional docs: ''${docsPath}
    - Examples: ''${examplesPath} (extensions, custom tools, SDK)
    - When asked about: extensions (docs/extensions.md, examples/extensions/), themes (docs/themes.md), skills (docs/skills.md), prompt templates (docs/prompt-templates.md), TUI components (docs/tui.md), keybindings (docs/keybindings.md), SDK integrations (docs/sdk.md), custom providers (docs/custom-provider.md), adding models (docs/models.md), pi packages (docs/packages.md)
    - When working on pi topics, read the docs and examples, and follow .md cross-references before implementing
    - Always read pi .md files completely and follow links to related docs (e.g., tui.md for TUI API details)

    After this template, pi may also append:
    - Project Context sections from AGENTS.md and related context files
    - Skills section
    - Current date: ''${date}
    - Current working directory: ''${promptCwd}
  '';

  defaultPiSystemPromptReference = ''
    You are an expert coding assistant operating inside pi, a coding agent harness. You help users by reading files, executing commands, editing code, and writing new files.

    Available tools:
    ''${toolsList}

    In addition to the tools above, you may have access to other custom tools depending on the project.

    Guidelines:
    ''${guidelines}

    Pi documentation (read only when the user asks about pi itself, its SDK, extensions, themes, skills, or TUI):
    - Main documentation: ''${readmePath}
    - Additional docs: ''${docsPath}
    - Examples: ''${examplesPath} (extensions, custom tools, SDK)
    - When asked about: extensions (docs/extensions.md, examples/extensions/), themes (docs/themes.md), skills (docs/skills.md), prompt templates (docs/prompt-templates.md), TUI components (docs/tui.md), keybindings (docs/keybindings.md), SDK integrations (docs/sdk.md), custom providers (docs/custom-provider.md), adding models (docs/models.md), pi packages (docs/packages.md)
    - When working on pi topics, read the docs and examples, and follow .md cross-references before implementing
    - Always read pi .md files completely and follow links to related docs (e.g., tui.md for TUI API details)

    After this template, pi may also append:
    - Project Context sections from AGENTS.md and related context files
    - Skills section
    - Current date: ''${date}
    - Current working directory: ''${promptCwd}
  '';

  piSettings = {
    defaultProvider = "anthropic";
    defaultModel = "claude-opus-4-6";
    defaultThinkingLevel = "high";
    enabledModels = [
      "openai-codex/gpt-5.4"
      "anthropic/claude-opus-4-6"
    ];
    compaction.enabled = false;
    showHardwareCursor = true;
    editorPaddingX = 0;
    steeringMode = "one-at-a-time";
    transport = "sse";
    hideThinkingBlock = true;
    collapseChangelog = true;
    quietStartup = false;
    doubleEscapeAction = "tree";
    treeFilterMode = "default";
    theme = "dark";
    packages = ["${piAgentsPkg}"];
  };
in {
  options.user.dev.pi = {
    enable = lib.mkEnableOption "pi coding agent CLI";
  };

  config = lib.mkIf config.user.dev.pi.enable {
    environment = {
      systemPackages = [
        piPkg
      ];
      variables.PI_AGENTS_PACKAGE = "${piAgentsPkg}";
    };

    bayt.users."${config.user.name}".files = {
      ".pi/agent/settings.json" = {
        text = builtins.toJSON piSettings;
      };
      ".pi/agent/system-prompt.md" = {
        text = defaultPiSystemPromptReference;
      };
      ".pi/agent/custom-system-prompt.md" = {
        text = customPiSystemPrompt;
      };
      ".pi/agent/extensions/custom-prompt.ts" = {
        text = ''
          import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
          import { readFileSync } from "node:fs";
          import { join } from "node:path";

          const CUSTOM_SYSTEM_PROMPT = readFileSync(
            join(process.env.HOME!, ".pi/agent/custom-system-prompt.md"),
            "utf8",
          );

          export default function (pi: ExtensionAPI) {
            pi.on("before_agent_start", async (_event, _ctx) => {
              return { systemPrompt: CUSTOM_SYSTEM_PROMPT };
            });
          }
        '';
      };
    };
  };
}
