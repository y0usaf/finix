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
            # Vercel gateway has no exclude list; whitelist every upstream
            # provider except moonshotai via vercelGatewayRouting.only.
            modelOverrides."anthropic/claude-fable-5" = {
              compat.vercelGatewayRouting.only = ["anthropic" "bedrock" "vertex"];
            };
            models = [
              {
                id = "moonshotai/kimi-k3-fast";
                name = "Kimi K3 Fast";
                api = "anthropic-messages";
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
              # DeepSeek upstream excluded (Chinese); Fireworks dropped for throughput (70tps vs 105tps).
              # Baseten first for lowest TTFT (0.9s); DeepInfra cheaper failover (2.3s TTFT, $0.09/$0.18).
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
                compat.vercelGatewayRouting.only = ["baseten" "deepinfra"];
                compat.vercelGatewayRouting.order = ["baseten" "deepinfra"];
              }
            ];
          };
        };
      };
    };
  };
}
