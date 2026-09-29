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
      defaultModel = "deepseek-v4.1-flash";
      defaultThinkingLevel = "max";

      enabledModels = [
        "vercel-ai-gateway/deepseek/deepseek-v4.1-flash"
        "opencode-go/deepseek-v4.1-flash"
        "anthropic/claude-opus-5.5"
        "anthropic/claude-sonnet-5.5"
      ];

      models = {
        providers.vercel-ai-gateway.modelOverrides."zai/glm-5.3-flash" = {
          compat.vercelGatewayRouting.order = ["runware" "wafer"];
        };

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
      flakeInputs.pi-flake.packages."${pkgs.stdenv.hostPlatform.system}".pi
    ];
    manzil.users."${config.user.name}".files = {
      ".pi/agent/settings.json" = {
        generator = toJSON;
        value = {
          inherit (catalog) defaultProvider defaultModel defaultThinkingLevel enabledModels;
          packages = [];
          compaction.enabled = false;
          showHardwareCursor = true;
          editorPaddingX = 0;
          steeringMode = "one-at-a-time";
          transport = "sse";
          skills = [
            "${./skills}"
          ];
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
