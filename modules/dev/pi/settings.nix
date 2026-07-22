{
  config,
  lib,
  ...
}: let
  cfg = config.user.dev.pi;
  toJSON = lib.generators.toJSON {};
  homeDir = config.user.homeDirectory;
  piReadmePath = cfg.readmePath;
  piDocsPath = cfg.docsPath;
  piExamplesPath = cfg.examplesPath;

  mkInternalStr = description:
    lib.mkOption {
      type = lib.types.str;
      internal = true;
      default = "";
      inherit description;
    };
in {
  options.user.dev.pi = {
    enable = lib.mkEnableOption "pi coding agent CLI";

    extensionSettings = lib.mkOption {
      type = with lib.types; attrsOf anything;
      internal = true;
      default = {};
      description = "Pi extension settings written to settings.json extensionSettings.";
    };

    readmePath = mkInternalStr "Path to the pi README.";
    docsPath = mkInternalStr "Path to the pi docs directory.";
    examplesPath = mkInternalStr "Path to the pi examples directory.";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = builtins.all (path: path != "") [
          piReadmePath
          piDocsPath
          piExamplesPath
        ];
        message = "user.dev.pi requires modules/dev/pi/pi-flake.nix to provide pi documentation paths.";
      }
    ];

    manzil.users."${config.user.name}".files = {
      ".local/share/pi/agent/settings.json" = {
        generator = toJSON;
        value =
          {
            defaultProvider = "vercel-ai-gateway";
            defaultModel = "moonshotai/kimi-k3";
            defaultThinkingLevel = "max";
            enabledModels = [
              "openai-codex/gpt-5.6-sol"
              "openai-codex/gpt-5.6-luna"
              "anthropic/claude-fable-5"
              "neuralwatt/glm-5.2"
              "vercel-ai-gateway/moonshotai/kimi-k3"
              "neuralwatt/kimi-k3"
            ];
            compaction.enabled = false;
            showHardwareCursor = true;
            editorPaddingX = 0;
            steeringMode = "one-at-a-time";
            transport = "sse";
            options = {
              skills_paths = [
                "./.codex/skills"
                "./.claude/skills"
              ];
            };
            hideThinkingBlock = false;
            collapseChangelog = true;
            quietStartup = true;
            doubleEscapeAction = "tree";
            treeFilterMode = "default";
          }
          // lib.optionalAttrs (cfg.extensionSettings != {}) {
            inherit (cfg) extensionSettings;
          };
      };
      ".local/share/pi/agent/models.json" = {
        generator = toJSON;
        value = {
          providers = {
            "neuralwatt" = {
              baseUrl = "https://api.neuralwatt.com/v1";
              api = "openai-completions";
              apiKey = "!cat ${homeDir}/Tokens/NEURALWATT_API_KEY.txt";
              authHeader = true;
              compat.supportsDeveloperRole = false;
              models = [
                {
                  id = "glm-5.2";
                  name = "GLM 5.2";
                  reasoning = true;
                  input = ["text" "image"];
                  contextWindow = 1048576;
                  maxTokens = 16384;
                  cost = {
                    input = 0;
                    output = 0;
                    cacheRead = 0;
                    cacheWrite = 0;
                  };
                }
                {
                  id = "glm-5.2-fast";
                  name = "GLM 5.2 Fast";
                  reasoning = true;
                  input = ["text" "image"];
                  contextWindow = 1048576;
                  maxTokens = 16384;
                  cost = {
                    input = 0;
                    output = 0;
                    cacheRead = 0;
                    cacheWrite = 0;
                  };
                }
                {
                  id = "kimi-k2.7-code";
                  name = "Kimi K2.7 Code";
                  reasoning = true;
                  input = ["text" "image"];
                  contextWindow = 262128;
                  maxTokens = 16384;
                  cost = {
                    input = 0;
                    output = 0;
                    cacheRead = 0;
                    cacheWrite = 0;
                  };
                }
                {
                  id = "kimi-k2.6";
                  name = "Kimi K2.6";
                  reasoning = true;
                  input = ["text" "image"];
                  contextWindow = 262128;
                  maxTokens = 16384;
                  cost = {
                    input = 0;
                    output = 0;
                    cacheRead = 0;
                    cacheWrite = 0;
                  };
                }
                {
                  id = "kimi-k3";
                  name = "Kimi K3";
                  reasoning = true;
                  thinkingLevelMap = {
                    off = null;
                    minimal = null;
                    low = null;
                    medium = null;
                    high = null;
                    xhigh = null;
                    max = "max";
                  };
                  input = ["text" "image"];
                  contextWindow = 1000000;
                  maxTokens = 131072;
                  cost = {
                    input = 0;
                    output = 0;
                    cacheRead = 0;
                    cacheWrite = 0;
                  };
                  compat.supportsReasoningEffort = true;
                }
                {
                  id = "qwen3.5-397b";
                  name = "Qwen 3.5 397B";
                  reasoning = true;
                  input = ["text" "image"];
                  contextWindow = 262128;
                  maxTokens = 16384;
                  cost = {
                    input = 0;
                    output = 0;
                    cacheRead = 0;
                    cacheWrite = 0;
                  };
                }
              ];
            };
            "vercel-ai-gateway" = {
              baseUrl = "https://ai-gateway.vercel.sh/v1";
              api = "openai-completions";
              apiKey = "!cat ${homeDir}/Tokens/AI_GATEWAY_API_KEY.txt";
              models = [
                {
                  id = "moonshotai/kimi-k3";
                  name = "Kimi K3";
                  reasoning = true;
                  input = ["text" "image"];
                  contextWindow = 1000000;
                  maxTokens = 131072;
                  cost = {
                    input = 3;
                    output = 15;
                    cacheRead = 0.3;
                    cacheWrite = 0;
                  };
                }
                {
                  id = "openai/gpt-oss-120b";
                  name = "GPT-OSS 120B (fast)";
                  reasoning = true;
                  input = ["text"];
                  contextWindow = 131072;
                  maxTokens = 131072;
                  cost = {
                    input = 0.1;
                    output = 0.5;
                    cacheRead = 0;
                    cacheWrite = 0;
                  };
                  compat.vercelGatewayRouting = {
                    only = ["cerebras" "groq" "baseten"];
                    order = ["cerebras" "groq" "baseten"];
                  };
                }
                {
                  id = "zai/glm-4.7";
                  name = "GLM 4.7 (Cerebras)";
                  reasoning = true;
                  input = ["text"];
                  contextWindow = 200000;
                  maxTokens = 120000;
                  cost = {
                    input = 0.6;
                    output = 2.2;
                    cacheRead = 0.12;
                    cacheWrite = 0;
                  };
                  compat.vercelGatewayRouting = {
                    only = ["cerebras" "baseten"];
                    order = ["cerebras" "baseten"];
                  };
                }
                {
                  id = "moonshotai/kimi-k2.5";
                  name = "Kimi K2.5 (Baseten)";
                  reasoning = true;
                  input = ["text" "image"];
                  contextWindow = 262144;
                  maxTokens = 262144;
                  cost = {
                    input = 0.6;
                    output = 3;
                    cacheRead = 0.1;
                    cacheWrite = 0;
                  };
                  compat.vercelGatewayRouting.only = ["baseten"];
                }
                {
                  id = "meta/llama-3.3-70b";
                  name = "Llama 3.3 70B (Groq)";
                  reasoning = false;
                  input = ["text"];
                  contextWindow = 128000;
                  maxTokens = 8192;
                  cost = {
                    input = 0.72;
                    output = 0.72;
                    cacheRead = 0;
                    cacheWrite = 0;
                  };
                  compat.vercelGatewayRouting.only = ["groq"];
                }
              ];
            };
          };
        };
      };
      ".local/share/pi/agent/DEFAULT_SYSTEM.md" = {
        text = ''
          You are an expert coding assistant operating inside pi, a coding agent harness. You help users by reading files, executing commands, editing code, and writing new files.

          Available tools:
          - read: Read file contents with hashline v2 LINEID anchors
          - bash: Execute bash commands (ls, grep, find, etc.)
          - edit: Patch files using hashline v2 LINEID anchors copied from read output
          - write: Create or overwrite files

          In addition to the tools above, you may have access to other custom tools depending on the project.

          Guidelines:
          - Use bash for file operations like ls, rg, find
          - Use read to examine files instead of cat or sed.
          - Use edit with anchors copied exactly from the latest read/edit output for that file.
          - Do not invent, shift, or construct anchors. If an anchor is stale or missing, call read again.
          - For edit content, provide literal file content only; no LINEID| prefixes and no diff +/- prefixes.
          - Prefer v2 loc/content edits: {range:{pos,end}} for replacements/deletes, {append}/{prepend} for inserts.
          - When changing multiple separate locations in one file, use one edit call with multiple entries in edits[] instead of multiple edit calls.
          - Do not emit overlapping or adjacent edits. Merge nearby changes into one replace range.
          - Use write only for new files or complete rewrites.
          - Be concise in your responses
          - Show file paths clearly when working with files

          Pi documentation (read only when the user asks about pi itself, its SDK, extensions, themes, skills, or TUI):
          - Main documentation: ${piReadmePath}
          - Additional docs: ${piDocsPath}
          - Examples: ${piExamplesPath} (extensions, custom tools, SDK)
          - When asked about: extensions (docs/extensions.md, examples/extensions/), themes (docs/themes.md), skills (docs/skills.md), prompt templates (docs/prompt-templates.md), TUI components (docs/tui.md), keybindings (docs/keybindings.md), SDK integrations (docs/sdk.md), custom providers (docs/custom-provider.md), adding models (docs/models.md), pi packages (docs/packages.md)
          - When working on pi topics, read the docs and examples, and follow .md cross-references before implementing
          - Always read pi .md files completely and follow links to related docs (e.g., tui.md for TUI API details)
        '';
      };
      ".local/share/pi/agent/SYSTEM.md" = {
        text = ''
          <role>Pi coding assistant</role>

          <tools>
            <tool name="read">Examine file contents with hashline v2 LINEID anchors</tool>
            <tool name="bash">Execute bash commands (ls, grep, find, rg)</tool>
            <tool name="edit">
              Patch files using hashline v2 LINEID anchors copied from read output.
              Prefer loc/content edits: {range:{pos,end}} for replacements/deletes, {append}/{prepend} for inserts.
              content must be literal file content; no LINEID| prefixes or diff +/- prefixes.
            </tool>
            <tool name="write">New files or complete rewrites only</tool>
          </tools>

          <rules>
            <rule>Use bash for file discovery (ls, find, rg)</rule>
            <rule>Use read to examine files, not cat or sed</rule>
            <rule>Use edit with anchors copied exactly from latest read/edit output; write only for new files or full rewrites</rule>
            <rule>Do not invent, shift, or construct anchors. If an anchor is stale or missing, call read again.</rule>
            <rule>Do not emit overlapping or adjacent edits. Merge nearby changes into one replace range.</rule>
            <rule>Be concise. Show file paths clearly.</rule>
            <rule>Only use compact symbols, operators, and abbreviations over prose when unambiguous (→, &, +, /, :, =, ≠, ≤, ≥, ✓, ✗, ±, ≈). Prefer forms like old → new, key=value, path: result. Avoid filler always.</rule>
            <rule>Prefer fragments over full sentences when clarity is preserved. Avoid restating the prompt or adding summaries unless asked.</rule>
          </rules>

          <pi-docs condition="only read when user asks about pi, SDK, extensions, themes, skills, or TUI">
            <path name="main">${piReadmePath}</path>
            <path name="docs">${piDocsPath}</path>
            <path name="examples">${piExamplesPath}</path>
            <topics>
              <topic key="extensions">docs/extensions.md, examples/extensions/</topic>
              <topic key="themes">docs/themes.md</topic>
              <topic key="skills">docs/skills.md</topic>
              <topic key="prompt-templates">docs/prompt-templates.md</topic>
              <topic key="tui">docs/tui.md</topic>
              <topic key="keybindings">docs/keybindings.md</topic>
              <topic key="sdk">docs/sdk.md</topic>
              <topic key="providers">docs/custom-provider.md</topic>
              <topic key="models">docs/models.md</topic>
              <topic key="packages">docs/packages.md</topic>
            </topics>
            Read docs fully. Follow cross-references before implementing.
          </pi-docs>
        '';
      };
    };
  };
}
