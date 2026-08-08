{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  cfg = config.user.dev.prime-agent;
  toJSON = lib.generators.toJSON {};
in {
  options.user.dev.prime-agent = {
    enable = lib.mkEnableOption "Prime Agent coding agent";

    defaultProvider = lib.mkOption {
      type = lib.types.str;
      default = "vercel-ai-gateway";
      description = "Default provider written to ~/.prime/agent/settings.json defaultProvider.";
    };

    defaultModel = lib.mkOption {
      type = lib.types.str;
      default = "deepseek/deepseek-v4-flash-0731";
      description = "Default model written to ~/.prime/agent/settings.json defaultModel.";
    };

    defaultThinkingLevel = lib.mkOption {
      type = lib.types.str;
      default = "high";
      description = "Default thinking level written to ~/.prime/agent/settings.json defaultThinkingLevel.";
    };

    enabledModels = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "vercel-ai-gateway/deepseek/deepseek-v4-flash-0731"
        "vercel-ai-gateway/anthropic/claude-fable-5"
        "vercel-ai-gateway/openai/gpt-5.6-sol"
        "openai-codex/gpt-5.6-sol"
      ];
      description = "Model patterns written to ~/.prime/agent/settings.json enabledModels for cycling.";
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
      description = "Freeform settings.json override, merged last so hosts can override any key.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      flakeInputs.prime-agent-flake.packages."${pkgs.stdenv.hostPlatform.system}".default
    ];

    manzil.users."${config.user.name}".files = {
      ".prime/agent/settings.json" = {
        generator = toJSON;
        value =
          {
            defaultProvider = cfg.defaultProvider;
            defaultModel = cfg.defaultModel;
            defaultThinkingLevel = cfg.defaultThinkingLevel;
            enabledModels = cfg.enabledModels;
            hideThinkingBlock = true;
          }
          // cfg.settings;
      };
    };
  };
}
