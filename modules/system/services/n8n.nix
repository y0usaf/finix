{
  lib,
  hostConfig,
  ...
}: let
  cfg = hostConfig.services.n8n or {};
in {
  config = lib.mkIf (cfg.enable or false) {
    services.n8n = {
      enable = true;
      openFirewall = cfg.openFirewall or false;
      settings = cfg.settings or {};
    };
  };
}
