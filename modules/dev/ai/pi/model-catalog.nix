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
  defaultModel = "openai/gpt-5.6-luna";
  defaultThinkingLevel = "max";

  enabledModels = [
    "vercel-ai-gateway/zai/glm-5.3-flash"
    "openrouter/stealth/ox-alpha"
    "vercel-ai-gateway/deepseek/deepseek-v4-pro-0813"
    "vercel-ai-gateway/deepseek/deepseek-v4-flash-0731"
    "inference/deepseek-v4-flash-0731"
    "vercel-ai-gateway/moonshotai/kimi-k3-fast"
    "vercel-ai-gateway/openai/gpt-5.6-sol"
    "vercel-ai-gateway/openai/gpt-5.6-luna"
    "anthropic/claude-fable-5"
    "anthropic/claude-opus-5"
    "openai-codex/gpt-5.6-sol"
    "openai-codex/gpt-5.6-luna"
  ];

  # Ox Alpha via OpenRouter builtin provider (OPENROUTER_API_KEY or
  # /login openrouter). Explicit api/baseUrl so the upsert resolves even
  # though the builtin catalog lacks this id.
  models.providers."openrouter" = {
    models = [
      {
        id = "stealth/ox-alpha";
        name = "Ox Alpha";
        api = "openai-completions";
        baseUrl = "https://openrouter.ai/api/v1";
        reasoning = true;
        input = ["text" "image"];
        contextWindow = 1048576;
        maxTokens = 131072;
      }
    ];
  };

  # Inference.net exposes an OpenAI-compatible Chat Completions endpoint.
  models.providers."inference" = {
    api = "openai-completions";
    baseUrl = "https://api.inference.net/v1";
    apiKey = "$INFERENCE_API_KEY";
    models = [
      {
        id = "deepseek-v4-flash-0731";
        name = "DeepSeek V4 Flash 0731 (Inference.net)";
        reasoning = true;
        input = ["text"];
        contextWindow = 128000;
        maxTokens = 16384;
      }
    ];
  };

  # Restrict GLM-5.3-Flash to the requested Vercel AI Gateway providers.
  models.providers."vercel-ai-gateway".modelOverrides."zai/glm-5.3-flash" = {
    compat.vercelGatewayRouting = {
      only = ["baseten" "wafer"];
      order = ["baseten" "wafer"];
    };
  };
}
