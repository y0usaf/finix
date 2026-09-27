{
  config,
  lib,
  ...
}: let
  catalog = config.user.dev.modelCatalog;
  toJSON = lib.generators.toJSON {};
in {
  manzil.users."${config.user.name}".files = {
    ".pi/agent/pi-agents.json" = {
      generator = toJSON;
      value = {
        maxDepth = 999;
        maxLiveAgents = 999;
        orchestrator = false;
        model = "${catalog.defaultProvider}/${catalog.defaultModel}";
        panelModels = [
          "vercel-ai-gateway/moonshotai/kimi-k3"
          "vercel-ai-gateway/anthropic/claude-fable-5"
          "vercel-ai-gateway/openai/gpt-5.6-sol"
        ];
      };
    };
  };
}
