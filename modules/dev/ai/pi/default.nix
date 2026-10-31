{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  catalog = config.user.dev.modelCatalog;
  toJSON = lib.generators.toJSON {};
in {
  options.user.dev.modelCatalog = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    description = "Shared coding-agent provider and model catalog.";
    default = {
      defaultProvider = "vercel-ai-gateway";
      defaultModel = "deepseek/deepseek-v4.1-flash-1017-fast";
      defaultThinkingLevel = "max";

      enabledModels = [
        "vercel-ai-gateway/deepseek/deepseek-v4.1-flash-1017-fast"
        "vercel-ai-gateway/deepseek/deepseek-v4.1-flash"
        "vercel-ai-gateway/deepseek/deepseek-v4.1-flash-1017"
        "anthropic/claude-opus-5-5"
        "anthropic/claude-sonnet-5-5"
      ];

      models = {
        providers.vercel-ai-gateway.modelOverrides."zai/glm-5.3-flash" = {
          compat.vercelGatewayRouting.order = ["runware" "wafer"];
        };

        providers.vercel-ai-gateway.models = [
          {
            id = "deepseek/deepseek-v4.1-flash-1017";
            name = "DeepSeek V4.1 Flash 1017";
            api = "anthropic-messages";
            reasoning = true;
            input = ["text" "image"];
            compat.allowEmptySignature = true;
            contextWindow = 1000000;
            maxTokens = 384000;
            cost = {
              input = 0.15;
              output = 0.6;
              cacheRead = 0.003;
              cacheWrite = 0;
            };
          }
          {
            id = "deepseek/deepseek-v4.1-flash-1017-fast";
            name = "DeepSeek V4.1 Flash 1017 Fast";
            api = "anthropic-messages";
            reasoning = true;
            input = ["text" "image"];
            compat.allowEmptySignature = true;
            contextWindow = 1000000;
            maxTokens = 384000;
            cost = {
              input = 0.6;
              output = 2.4;
              cacheRead = 0.014;
              cacheWrite = 0;
            };
          }
          {
            id = "moonshotai/kimi-k3.1-pro";
            name = "Kimi K3.1 Pro";
            api = "anthropic-messages";
            reasoning = true;
            input = ["text" "image"];
            compat.allowEmptySignature = true;
            contextWindow = 1000000;
            maxTokens = 131072;
            cost = {
              input = 2;
              output = 10;
              cacheRead = 0.2;
              cacheWrite = 0;
            };
          }
          {
            id = "moonshotai/kimi-k3.1-pro-highspeed";
            name = "Kimi K3.1 Pro High Speed";
            api = "anthropic-messages";
            reasoning = true;
            input = ["text" "image"];
            compat.allowEmptySignature = true;
            contextWindow = 1000000;
            maxTokens = 131072;
            cost = {
              input = 4;
              output = 20;
              cacheRead = 0.2;
              cacheWrite = 0;
            };
          }
        ];

        providers.celeris = {
          name = "Celeris";
          baseUrl = "https://inference.celeris.ai/celeris-1-magnus/v1";
          api = "openai-completions";
          apiKey = "$CELERIS_API_KEY";
          models = [
            {
              id = "celeris-1-magnus";
              name = "Celeris 1 Magnus";
              reasoning = true;
              contextWindow = 128000;
              maxTokens = 8192;
              cost = {
                input = 0;
                output = 0;
                cacheRead = 0;
                cacheWrite = 0;
              };
            }
          ];
        };

        providers.bonsai = {
          name = "Bonsai (local)";
          baseUrl = "http://127.0.0.1:8891/v1";
          api = "openai-completions";
          apiKey = "none";
          models = [
            {
              id = "bonsai";
              name = "Ternary Bonsai 2 27B (local)";
              reasoning = true;
              thinkingLevelMap = {xhigh = "xhigh";};
              contextWindow = 32768;
              maxTokens = 8192;
              cost = {
                input = 0;
                output = 0;
                cacheRead = 0;
                cacheWrite = 0;
              };
            }
          ];
        };
      };
    };
  };

  config = {
    finix.persistence.allowlist.users.${config.user.name}.directories = [
      ".config/pi/agent"
      ".config/pi-harness"
      ".local/share/pi"
      ".local/state/pi-harness"
      ".pi"
    ];
    environment.systemPackages = [
      flakeInputs.pi-harness.packages."${pkgs.stdenv.hostPlatform.system}".default
    ];
    environment.variables.PI_SKIP_VERSION_CHECK = "1";
    manzil.users."${config.user.name}".files = {
      ".pi/agent/settings.json" = {
        generator = toJSON;
        value = {
          inherit (catalog) defaultProvider defaultModel defaultThinkingLevel enabledModels;
          packages = [
            "${flakeInputs.pi-chronobreak}"
            "${flakeInputs.pi-rlm}"
            "${flakeInputs.pi-recap}"
            "${flakeInputs.pi-accounts}"
            "${flakeInputs.pi-ampersand}"
            "${flakeInputs.pi-donsetch.packages."${pkgs.stdenv.hostPlatform.system}".default}"
          ];
          enableInstallTelemetry = false;
          defaultTools = ["+codemode"];
          codemode.mode = "only";
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
          symbols = {
            preset = "ascii";
            overrides = {};
          };
          recap = {
            placement = "above";
            model = lib.head catalog.enabledModels;
          };
        };
      };
      ".pi/agent/models.json" = {
        generator = toJSON;
        value = catalog.models;
      };

      ".pi/workflows/goal-loop.json".source = ./goal-loop.json;
    };
  };
}
