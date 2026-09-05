{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkEnableOption mkIf optionalAttrs listToAttrs nameValuePair;
  devCfg = config.user.dev;
  cfg = devCfg.opencode;
  homeDir = config.user.homeDirectory;
  toJson = lib.generators.toJSON {};
  mkStrOption = default: description:
    mkOption {
      type = types.str;
      inherit default description;
    };
  mkBoolOption = default: description:
    mkOption {
      type = types.bool;
      inherit default description;
    };
in {
  options.user.dev.opencode = {
    enable = mkEnableOption "opencode AI coding agent";

    theme = mkStrOption "system" "Theme to use for opencode";

    model = mkStrOption "neuralwatt/glm-5.2" "Default model to use";

    enableMcpServers = mkBoolOption false "Enable MCP servers for enhanced functionality";

    enableLsps = mkBoolOption true "Enable LSP servers for diagnostics";

    enableOllama = mkBoolOption false "Enable local Ollama provider for opencode";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.opencode
      pkgs.uv
      pkgs.nixd
    ];
    manzil.users."${config.user.name}" = {
      files = {
        ".config/opencode/opencode.json" = {
          generator = toJson;
          value =
            {
              "$schema" = "https://opencode.ai/config.json";
              inherit (cfg) model;
              autoupdate = true;
              share = "manual";
              disabled_providers = ["openai" "huggingface"];
              instructions = [
                "AGENTS.md"
                ".cursor/rules/*.md"
                "{file:${homeDir}/.config/opencode/claude-instructions.md}"
                "{file:${homeDir}/.config/opencode/opencode-instructions.md}"
              ];
            }
            // (optionalAttrs cfg.enableLsps {lsp = {};})
            // (optionalAttrs cfg.enableOllama {
              inherit
                ({
                  provider = {
                    ollama = {
                      npm = "@ai-sdk/openai-compatible";
                      name = "Ollama (local)";
                      options = {
                        baseURL = "http://localhost:11434/v1";
                      };
                      models = {
                        "deepseek-coder-v2:16b" = {
                          name = "DeepSeek Coder V2 (16B MoE)";
                          description = "Excellent code reasoning, MoE with --cpu-moe optimization";
                        };
                        "qwen2.5-coder:32b" = {
                          name = "Qwen 2.5 Coder (32B)";
                          description = "State-of-the-art code generation and understanding";
                        };
                        "qwq:32b" = {
                          name = "QwQ (32B Reasoning)";
                          description = "DeepSeek's reasoning-specialized model for complex problems";
                        };
                        "qwen2.5:32b" = {
                          name = "Qwen 2.5 (32B)";
                          description = "Excellent multilingual and general-purpose capabilities";
                        };
                        "nomic-embed-text:latest" = {
                          name = "Nomic Embed Text";
                          description = "Embeddings for RAG workflows";
                        };
                      };
                    };
                  };
                })
                provider
                ;
            })
            // (optionalAttrs cfg.enableMcpServers {
              mcp = listToAttrs (map
                (spec:
                  nameValuePair spec.name {
                    type = "local";
                    command = [spec.command] ++ spec.args;
                    enabled = true;
                    inherit (spec) environment;
                  })
                [
                  {
                    name = "Filesystem";
                    command = "npx";
                    args = ["-y" "@modelcontextprotocol/server-filesystem" homeDir];
                    environment = {};
                  }
                  {
                    name = "GitHub Repo MCP";
                    command = "npx";
                    args = ["-y" "github-repo-mcp"];
                    environment = {};
                  }
                  {
                    name = "Gemini MCP";
                    command = "npx";
                    args = ["-y" "gemini-mcp-tool"];
                    environment = {};
                  }
                ]);
            });
        };

        ".config/opencode/tui.json" = {
          clobber = true;
          generator = toJson;
          value = {
            "$schema" = "https://opencode.ai/tui.json";
            inherit (cfg) theme;
          };
        };

        ".config/opencode/claude-instructions.md" = {
          text = ''
            Give candid, evidence-based feedback. State concrete strengths and
            problems when relevant. Avoid reflexive praise and filler.
          '';
        };

        ".config/opencode/opencode-instructions.md" = {
          text = ''
            Complete the user's task with the least work that produces a correct,
            verified result. Prefer focused changes and established patterns.

            Work:
            - Inspect relevant code before making claims. Start with scoped rg
              searches and short excerpts. Reuse findings; expand when needed.
            - Work locally by default. Use Task only for substantial, independent
              work whose benefit exceeds setup and duplicated context. Give each
              child relevant paths, a bounded scope, and a concise result contract.
            - Batch independent tool calls. Use only tools available in this
              session. Read relevant documentation sections; follow references
              when needed to resolve missing details.
            - Use TodoWrite for complex work. Update changed status without
              repeating the plan. Routine edits need no planning ceremony.
            - Check git status, preserve unrelated edits, and review the diff.
              When committing is requested, follow existing commit conventions.
            - Format changed files and run relevant existing checks. Expand
              verification for failures or affected dependencies. Stop once the
              requested outcome and required checks are complete.
            - If attempts fail repeatedly, revisit the hypothesis before editing.
              Ask when missing information blocks correctness or an action needs
              authorization. Honor authorization already given; otherwise proceed
              with reasonable, stated assumptions for routine work.

            Automation (long-running or unattended tasks):
            - Preserve the goal, constraints, and completion criteria. Continue
              across milestones without routine confirmation.
              Treat follow-ups as steering unless they replace or cancel the goal.
            - Save a concise checkpoint at milestones and before compaction or
              handoff when possible. Use existing task-state support or a
              task-scoped file in the authorized workspace. Record the goal,
              constraints, completion criteria, completed work, key decisions,
              artifact paths, verification, pending actions, and the next step;
              omit raw logs. Update one checkpoint instead of appending a running
              transcript. Give delegated tasks distinct checkpoint ownership.
            - On resume, read the checkpoint and verify current state. Reuse
              completed work. Retry transient failures only when safe; inspect
              the outcome of an uncertain write before repeating it. Never assume
              a timeout means a write failed. Change approach after repeated
              failures; do not retry unchanged actions indefinitely.
            - For recurring jobs, inspect prior results and current state; apply
              only missing work.
            - When blocked, continue independent work. If no progress is possible
              in an unattended run, report the missing input or permission and stop.
            - Respect explicit budgets and deadlines. Report completion only with
              evidence; otherwise state blocked or budget-exhausted, what remains,
              and the next step. Report meaningful milestones and state changes
              without repetitive heartbeat text. A progress update does not end
              the task.

            Finix:
            - Use manzil for user configuration. Check flake.nix for inputs.
            - Put any needed external checkouts under tmp/.
            - Format changed Nix files with alejandra. Use relevant project checks
              and nh os switch --dry for system configuration work as appropriate.
              Run nh os switch when system activation is requested.

            Communication:
            - Lead with the result. Use plain language and short paragraphs.
              Keep routine updates to one sentence. Usually finish in three
              bullets or fewer: result, verification, and any unresolved issue.
            - Explain causes and tradeoffs when needed for understanding or
              requested. Cite relevant paths and distinguish facts from assumptions.
            - Skip greetings, filler, repeated plans, recaps, and unsolicited
              next steps. Add detail when the task requires it.
          '';
        };
      };
    };
  };
}
