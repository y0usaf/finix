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
      ".pi/agent/pi-agents.json" = {
        generator = toJSON;
        value =
          {
            inherit (cfg.agents) maxDepth maxLiveAgents orchestrator;
          }
          // lib.optionalAttrs (cfg.agents.model != null) {
            inherit (cfg.agents) model;
          }
          // lib.optionalAttrs (cfg.agents.panelModels != []) {
            inherit (cfg.agents) panelModels;
          };
      };
    };
  };
}
