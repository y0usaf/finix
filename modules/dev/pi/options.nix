{
  config,
  lib,
  ...
}: let
  cfg = config.user.dev.pi;

  inherit (lib) types;
  nullOrStr = types.nullOr types.str;

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

    defaultProvider = lib.mkOption {
      type = types.str;
      default = "vercel-ai-gateway";
      description = "Default provider written to settings.json defaultProvider.";
    };

    defaultModel = lib.mkOption {
      type = types.str;
      default = "anthropic/claude-fable-5";
      description = "Default model written to settings.json defaultModel.";
    };

    defaultThinkingLevel = lib.mkOption {
      type = types.str;
      default = "max";
      description = "Default thinking level written to settings.json defaultThinkingLevel.";
    };

    enabledModels = lib.mkOption {
      type = types.listOf types.str;
      default = [
        "deepseek/deepseek-v4-flash-0731"
        "openai-codex/gpt-5.6-sol"
        "openai-codex/gpt-5.6-luna"
        "anthropic/claude-fable-5"
        "anthropic/claude-opus-5"
        "moonshotai/kimi-k3-fast"
      ];
      description = "Models written to settings.json enabledModels.";
    };

    settings = lib.mkOption {
      type = types.attrsOf types.anything;
      default = {};
      description = "Freeform settings.json override, merged last so hosts can override any key.";
    };

    readmePath = mkInternalStr "Path to the pi README.";
    docsPath = mkInternalStr "Path to the pi docs directory.";
    examplesPath = mkInternalStr "Path to the pi examples directory.";

    agents = {
      model = lib.mkOption {
        type = nullOrStr;
        default = "vercel-ai-gateway/deepseek/deepseek-v4-flash-0731";
        description = ''
          Model for pi-agents spawned children, written to
          `~/.pi/agent/pi-agents.json`. Use a qualified
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
  };
}
