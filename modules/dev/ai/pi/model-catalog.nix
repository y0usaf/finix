# Shared model/provider catalog for the pi, prime-agent, and omp coding agents.
# Prime Agent is the same pi core (its bundle ships as share/pi), so both read
# the identical settings.json / models.json schema. Loader semantics verified
# in both bundles (pi 0.84.1 provider-composer.js, prime-agent 0.7.2
# model-registry.js):
#   - per-model upserts with explicit api/baseUrl behave identically in both;
#   - provider-level `api` only defaults into upserted `models` entries and
#     never re-apis builtin models;
#   - `modelOverrides` merge onto builtin models last and cannot change
#     api/baseUrl.
# Plain data file (no options/config): excluded from the module walk in
# modules/finix/default.nix, imported directly by options.nix and
# prime-agent.nix.
{
  defaultProvider = "vercel-ai-gateway";
  defaultModel = "zai/glm-5.3-flash@wafer";
  defaultThinkingLevel = "max";

  enabledModels = [
    "vercel-ai-gateway/zai/glm-5.3-flash@wafer"
    "vercel-ai-gateway/openai/gpt-5.6-luna@azure"
    "openai-codex/gpt-5.6-luna"
  ];

  # Custom OpenAI-compatible provider (key resolved from $CELERIS_API_KEY at
  # runtime via the `$VAR` config-value template, never stored in the Nix store).
  models = {
    providers.vercel-ai-gateway.modelOverrides."zai/glm-5.3-flash" = {
      compat.vercelGatewayRouting.order = [ "runware" "wafer" ];
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
  };
}
