{lib, ...}: {
  options.user.dev.modelCatalog = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    description = "Shared coding-agent provider and model catalog.";
    default = {
      defaultProvider = "opencode-go";
      defaultModel = "deepseek-v4.1-flash";
      defaultThinkingLevel = "max";

      enabledModels = [
        "vercel-ai-gateway/deepseek/deepseek-v4.1-flash@wafer"
        "opencode-go/deepseek-v4.1-flash"
        "openai-codex/gpt-6-astra"
        "vercel-ai-gateway/zai/glm-5.3-flash@wafer"
        "vercel-ai-gateway/openai/gpt-5.6-luna@azure"
        "openai-codex/gpt-5.6-luna"
        "bonsai/bonsai"
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
}
