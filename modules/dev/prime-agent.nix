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

    models = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {
        providers."vercel-ai-gateway" = {
          # openai-completions is the only api that emits vercelGatewayRouting;
          # anthropic-messages (the built-in default) drops it. baseUrl is
          # per-model: openai models need /v1 (client uses baseUrl verbatim),
          # while anthropic-messages models must NOT get /v1 (SDK appends
          # /v1/messages -> double path -> 404).
          api = "openai-completions";
          # Vercel gateway has no exclude list; whitelist every upstream
          # provider except moonshotai via vercelGatewayRouting.only.
          modelOverrides."anthropic/claude-fable-5" = {
            compat.vercelGatewayRouting.only = ["anthropic" "bedrock" "vertex"];
          };
          models = [
            {
              id = "moonshotai/kimi-k3-fast";
              name = "Kimi K3 Fast";
              baseUrl = "https://ai-gateway.vercel.sh/v1";
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
            # Baseten first for lowest TTFT; Novita failover. DeepSeek upstream excluded (Chinese).
            {
              id = "deepseek/deepseek-v4-flash-0731";
              name = "DeepSeek V4 Flash 0731";
              baseUrl = "https://ai-gateway.vercel.sh/v1";
              reasoning = true;
              input = ["text"];
              cost = {
                input = 0.13;
                output = 0.26;
                cacheRead = 0.03;
                cacheWrite = 0;
              };
              contextWindow = 1000000;
              maxTokens = 384000;
              compat.vercelGatewayRouting.only = ["wafer" "baseten"];
              compat.vercelGatewayRouting.order = ["wafer" "baseten"];
            }
          ];
        };
      };
      description = "Model definitions written to ~/.prime/agent/models.json.";
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

      ".prime/agent/models.json" = {
        generator = toJSON;
        value = cfg.models;
      };
    };
  };
}
