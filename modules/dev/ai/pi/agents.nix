{
  config,
  lib,
  ...
}: let
  cfg = config.user.dev.pi;
  catalog = config.user.dev.modelCatalog;
  toJSON = lib.generators.toJSON {};
in {
  config = lib.mkIf cfg.enable {
    manzil.users."${config.user.name}".files = {
      ".pi/agent/pi-agents.json" = {
        generator = toJSON;
        value = {
          inherit (cfg.agents) maxDepth maxLiveAgents;
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
  };
}
