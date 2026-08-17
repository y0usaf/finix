# Shared model/provider catalog for the pi and prime-agent coding agents.
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
  defaultModel = "deepseek/deepseek-v4-pro-0813";
  defaultThinkingLevel = "max";

  enabledModels = [
    "vercel-ai-gateway/deepseek/deepseek-v4-pro-0813"
    "vercel-ai-gateway/deepseek/deepseek-v4-flash-0731"
    "vercel-ai-gateway/moonshotai/kimi-k3-fast"
    "vercel-ai-gateway/anthropic/claude-fable-5"
    "vercel-ai-gateway/openai/gpt-5.6-sol"
    "vercel-ai-gateway/openai/gpt-5.6-luna"
    "anthropic/claude-fable-5"
    "anthropic/claude-opus-5"
    "openai-codex/gpt-5.6-sol"
    "openai-codex/gpt-5.6-luna"
  ];

  models.providers."vercel-ai-gateway" = {
    # Vercel gateway has no exclude list; whitelist upstream providers via
    # vercelGatewayRouting.only. Only openai-completions emits the routing
    # payload; anthropic-messages drops it, so this override is inert while
    # fable-5 rides the builtin anthropic-messages entry and takes effect if
    # it is ever upserted onto openai-completions.
    modelOverrides."anthropic/claude-fable-5" = {
      compat.vercelGatewayRouting.only = ["anthropic" "bedrock" "vertex"];
    };
    models = [
      # Mirrors the pi 0.84.1 builtin gateway entry verbatim: prime-agent
      # 0.7.2's builtin catalog lacks this id, so without the upsert the
      # shared defaultModel cannot resolve there. anthropic-messages baseUrl
      # must NOT carry /v1 (the SDK appends /v1/messages).
      {
        id = "deepseek/deepseek-v4-pro-0813";
        name = "DeepSeek V4 Pro 0813";
        api = "anthropic-messages";
        baseUrl = "https://ai-gateway.vercel.sh";
        reasoning = true;
        input = ["text"];
        cost = {
          input = 0.435;
          output = 0.87;
          cacheRead = 0.0036;
          cacheWrite = 0;
        };
        contextWindow = 1000000;
        maxTokens = 384000;
      }
      # Flash models pinned to the wafer provider via openai-completions (the
      # only api that emits vercelGatewayRouting); openai-completions baseUrl
      # needs /v1 (the client uses it verbatim). Params mirror the gateway
      # catalog (ai-gateway.vercel.sh/v1/models).
      {
        id = "deepseek/deepseek-v4-flash-0731";
        name = "DeepSeek V4 Flash 0731";
        reasoning = true;
        input = ["text"];
        cost = {
          input = 0.2;
          output = 0.4;
          cacheRead = 0.04;
          cacheWrite = 0;
        };
        contextWindow = 1000000;
        maxTokens = 384000;
        api = "openai-completions";
        baseUrl = "https://ai-gateway.vercel.sh/v1";
        compat.vercelGatewayRouting.only = ["wafer"];
      }
      {
        id = "deepseek/deepseek-v4-flash";
        name = "DeepSeek V4 Flash";
        reasoning = true;
        input = ["text"];
        cost = {
          input = 0.2;
          output = 0.4;
          cacheRead = 0.04;
          cacheWrite = 0;
        };
        contextWindow = 1000000;
        maxTokens = 384000;
        api = "openai-completions";
        baseUrl = "https://ai-gateway.vercel.sh/v1";
        compat.vercelGatewayRouting.only = ["wafer"];
      }
      # Kimi pinned to fireworks (from the old prime-agent module); shared
      # here so pi gets the same pin instead of the builtin unpinned
      # anthropic-messages entry.
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
        api = "openai-completions";
        compat.vercelGatewayRouting.only = ["fireworks"];
      }
    ];
  };
}
