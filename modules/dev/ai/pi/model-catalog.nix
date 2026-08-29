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
    "vercel-ai-gateway/zai/glm-5.3-flash"
    "vercel-ai-gateway/deepseek/deepseek-v4-flash-0731"
    "vercel-ai-gateway/openai/gpt-5.6-luna"
    "openai-codex/gpt-5.6-luna"
  ];

  models.providers."vercel-ai-gateway" = {
    models = [
      {
        id = "moonshotai/kimi-k3-fast";
        name = "Kimi K3 Fast";
        api = "openai-completions";
        baseUrl = "https://ai-gateway.vercel.sh/v1";
        reasoning = true;
        input = ["text" "image"];
        contextWindow = 1000000;
        maxTokens = 131072;
        cost = {
          input = 4.5;
          output = 22.5;
          cacheRead = 0.45;
          cacheWrite = 0;
        };
        compat.vercelGatewayRouting.only = ["fireworks"];
      }
    ];
  };

  models.providers."groq" = {
    baseUrl = "https://api.groq.com/openai/v1";
    api = "openai-completions";
    apiKey = "!cat /home/y0usaf/Tokens/GROQ_API_KEY.txt";
    models = [
      {
        id = "llama-3.3-70b-versatile";
        name = "Llama 3.3 70B";
        reasoning = false;
        input = ["text"];
        contextWindow = 131072;
        maxTokens = 32768;
        cost = {
          input = 0.59;
          output = 0.79;
          cacheRead = 0;
          cacheWrite = 0;
        };
      }
      {
        id = "llama-3.1-8b-instant";
        name = "Llama 3.1 8B Instant";
        reasoning = false;
        input = ["text"];
        contextWindow = 131072;
        maxTokens = 8192;
        cost = {
          input = 0.05;
          output = 0.08;
          cacheRead = 0;
          cacheWrite = 0;
        };
      }
      {
        id = "moonshotai/kimi-k2-instruct-0905";
        name = "Kimi K2 Instruct";
        reasoning = false;
        input = ["text"];
        contextWindow = 262144;
        maxTokens = 16384;
        cost = {
          input = 1.0;
          output = 3.0;
          cacheRead = 0;
          cacheWrite = 0;
        };
      }
      {
        id = "openai/gpt-oss-120b";
        name = "GPT-OSS 120B";
        reasoning = true;
        input = ["text"];
        contextWindow = 131072;
        maxTokens = 65536;
        cost = {
          input = 0.15;
          output = 0.75;
          cacheRead = 0;
          cacheWrite = 0;
        };
      }
    ];
  };
}
