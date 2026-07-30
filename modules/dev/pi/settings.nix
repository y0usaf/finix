{
  config,
  lib,
  ...
}: let
  cfg = config.user.dev.pi;
  inherit (lib) types;
  nullOrStr = types.nullOr types.str;
  toJSON = lib.generators.toJSON {};

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

    agents = {
      model = lib.mkOption {
        type = nullOrStr;
        default = "vercel-ai-gateway/openai/gpt-5.6-luna";
        description = ''
          Model for pi-agents spawned children, written to
          `~/.local/share/pi/agent/pi-agents.json`. Use a qualified
          `provider/modelId` pair (for example `cursor/composer-2.5`).
        '';
      };

      maxDepth = lib.mkOption {
        type = types.int;
        default = 1;
        description = ''
          Maximum descendant depth for pi-agents. Depth 0 disables spawning.
        '';
      };

      maxLiveAgents = lib.mkOption {
        type = types.int;
        default = 6;
        description = ''
          Maximum number of live pi-agents children kept in memory.
        '';
      };

      orchestrator = lib.mkOption {
        type = types.bool;
        default = true;
        description = ''
          Strip write/edit from the main pi session at session start so
          file mutations route through spawned executor agents. Toggle
          per-session with /orchestrate.
        '';
      };

      panelModels = lib.mkOption {
        type = types.listOf types.str;
        default = [
          "vercel-ai-gateway/moonshotai/kimi-k3"
          "vercel-ai-gateway/anthropic/claude-fable-5"
          "vercel-ai-gateway/openai/gpt-5.6-sol"
        ];
        description = ''
          Panel member models for pi-agents spawn_agent panels, in seat
          order. The extension requires between 2 and 5 entries and
          rejects other lengths at load. An empty list omits the key so
          panels fall back to `model`.
        '';
      };
    };
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
            defaultProvider = "anthropic";
            defaultModel = "claude-opus-5";
            defaultThinkingLevel = "max";
            enabledModels = [
              "openai-codex/gpt-5.6-sol"
              "openai-codex/gpt-5.6-luna"
              "anthropic/claude-fable-5"
              "anthropic/claude-opus-5"
              "moonshotai/kimi-k3-fast"
              "cursor/composer-2"
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
            hideThinkingBlock = true;
            collapseChangelog = true;
            quietStartup = true;
            doubleEscapeAction = "tree";
            treeFilterMode = "default";
          }
          // lib.optionalAttrs (cfg.extensionSettings != {}) {
            inherit (cfg) extensionSettings;
          };
      };
      ".local/share/pi/agent/interview.json" = {
        generator = toJSON;
        value = {
          mode = "strict";
          provider = "openai-codex";
          model = "gpt-5.6-luna";
        };
      };
      ".local/share/pi/agent/models.json" = {
        generator = toJSON;
        value = {
          providers."vercel-ai-gateway" = {
            # Vercel gateway has no exclude list; whitelist every upstream
            # provider except moonshotai via vercelGatewayRouting.only.
            modelOverrides."anthropic/claude-fable-5" = {
              compat.vercelGatewayRouting.only = ["anthropic" "bedrock" "vertex"];
            };
            models = [
              {
                id = "moonshotai/kimi-k3-fast";
                name = "Kimi K3 Fast";
                api = "anthropic-messages";
                reasoning = true;
                input = ["text" "image"];
                cost = {
                  input = 4.5;
                  output = 22.5;
                  cacheRead = 0.45;
                  cacheWrite = 0;
                };
                contextWindow = 1000000;
                maxTokens = 131072;
                compat.vercelGatewayRouting.only = ["fireworks"];
              }
            ];
          };
        };
      };

      ".local/share/pi/agent/pi-agents.json" = {
        generator = toJSON;
        value =
          {
            inherit (cfg.agents) maxDepth maxLiveAgents orchestrator;
          }
          // lib.optionalAttrs (cfg.agents.model != null) {
            inherit (cfg.agents) model;
          }
          // lib.optionalAttrs (cfg.agents.panelModels != []) {
            inherit (cfg.agents) panelModels;
          };
      };
    };
  };
}
