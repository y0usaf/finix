{
  config,
  lib,
  ...
}: let
  cfg = config.user.dev.pi;
  toJSON = lib.generators.toJSON {};
in {
  config = lib.mkIf cfg.enable {
    manzil.users."${config.user.name}".files = {
      ".pi/agent/models.json" = {
        generator = toJSON;
        value = {
          providers."vercel-ai-gateway" = {
            # openai-completions is the only api that emits vercelGatewayRouting;
            # anthropic-messages (the built-in default) drops it. baseUrl needs
            # /v1 because the openai client uses baseUrl verbatim.
            baseUrl = "https://ai-gateway.vercel.sh/v1";
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
                compat.vercelGatewayRouting.only = ["baseten" "novita"];
                compat.vercelGatewayRouting.order = ["baseten" "novita"];
              }
            ];
          };
        };
      };
    };
  };
}
