{lib, ...}: {
  options.user.dev.modelCatalog = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    description = "Shared coding-agent provider and model catalog.";
    default =
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
      # Exposed through module configuration for all coding-agent consumers.
      {
        # DeepSeek V4.1 Flash through the Vercel AI Gateway. The
        # pi-vercel-ai-gateway extension enforces `@endpoint` as a hard
        # allowlist, so one endpoint is pinned. Account constraints (live
        # gateway probes 2026-09-10): `@deepseek` is not enabled for the team,
        # `@gmicloud`/`@novita` fail the account's ZDR requirement, and
        # `@baseten`/`@morph`/`@parasail` returned 503. `@fireworks` works and
        # is the cheapest routable endpoint ($0.22 in / $0.66 out per M, $0.007
        # cache read, 1.048M ctx); `@deepinfra` ($0.30/$1.20) is the working
        # alternative.
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

        # Custom OpenAI-compatible provider (key resolved from $CELERIS_API_KEY at
        # runtime via the `$VAR` config-value template, never stored in the Nix store).
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

          # Local OpenAI-compatible provider for a ternarily-quantized Bonsai 2 27B,
          # served ON DEMAND, never resident (09-18 verdict: on a 24 GB card the same
          # VRAM buys a stronger 27B, and the 27B plateaus at ~80 tok/s -- the 8B is
          # dropped outright: at temp 1.0 it is not agent-worthy). The server only
          # answers while it is running; selecting this model with it down errors on
          # connection. The model dir was parked by the 2026-09-18 sandbox cull, so
          # restore and launch (~30 s cold load) before use:
          #   mv ~/dev/trash/sandbox-20260918/bonsai-ternary-20260917 ~/dev/sandbox/
          #   ~/dev/sandbox/bonsai-ternary-20260917/start-server.sh   # :8891, alias bonsai
          # apiKey `none` sends no Authorization header.
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
                # llama-server's embedded Jinja template accepts only xhigh/medium/low.
                # Pin pi's extended levels onto the template's own default ("xhigh");
                # pi's global defaultThinkingLevel "max" then clamps to this entry.
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
