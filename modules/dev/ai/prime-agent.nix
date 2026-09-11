{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  cfg = config.user.dev.prime-agent;
  # Shared pi/prime-agent model catalog (plain data, see
  # modules/dev/ai/pi/model-catalog.nix).
  catalog = config.user.dev.modelCatalog;
  toJSON = lib.generators.toJSON {};
in {
  # Prime Agent is the pi core plus the Prime RLM/harness layer; it reads the
  # same settings.json/models.json schema from ~/.prime/agent/ instead of
  # ~/.pi/agent/, so its model catalog is shared with pi via model-catalog.nix.
  options.user.dev.prime-agent = {
    enable = lib.mkEnableOption "Prime Agent coding agent";

    defaultProvider = lib.mkOption {
      type = lib.types.str;
      default = catalog.defaultProvider;
      description = "Default provider written to ~/.prime/agent/settings.json defaultProvider.";
    };

    defaultModel = lib.mkOption {
      type = lib.types.str;
      default = catalog.defaultModel;
      description = "Default model written to ~/.prime/agent/settings.json defaultModel.";
    };

    defaultThinkingLevel = lib.mkOption {
      type = lib.types.str;
      default = catalog.defaultThinkingLevel;
      description = "Default thinking level written to ~/.prime/agent/settings.json defaultThinkingLevel.";
    };

    enabledModels = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = catalog.enabledModels;
      description = "Model patterns written to ~/.prime/agent/settings.json enabledModels for cycling.";
    };

    rlmMaxDepth = lib.mkOption {
      type = lib.types.int;
      default = 999;
      description = ''
        RLM subagent recursion cap written to settings.json rlmMaxDepth.
        Resolution order in agent-session.js: per-chat /rlm override >
        depth inherited from the parent > this global setting >
        RLM_MAX_DEPTH env > default 1. 999 is effectively unlimited.
      '';
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
      description = "Freeform settings.json override, merged last so hosts can override any key.";
    };

    models = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = catalog.models;
      description = "Model definitions written to ~/.prime/agent/models.json.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      flakeInputs.pi-flake.packages."${pkgs.stdenv.hostPlatform.system}".prime-agent
    ];

    manzil.users."${config.user.name}".files = {
      ".prime/agent/settings.json" = {
        generator = toJSON;
        value =
          {
            inherit (cfg) defaultProvider;
            inherit (cfg) defaultModel;
            inherit (cfg) defaultThinkingLevel;
            inherit (cfg) enabledModels;
            inherit (cfg) rlmMaxDepth;
            hideThinkingBlock = true;
            # The shared catalog's default is a
            # vercel-ai-gateway `model@endpoint` id, which only exists once
            # this extension registers the provider; prime-agent's built-in
            # catalog has no DeepSeek V4.1 and no explicit-endpoint variants.
            packages = [
              "/home/y0usaf/dev/maintaining/pi-flake/extensions/pi-vercel-ai-gateway"
            ];
          }
          // cfg.settings;
      };

      ".prime/agent/models.json" = {
        generator = toJSON;
        value = cfg.models;
      };
    };
  };
}
