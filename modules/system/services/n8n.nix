{
  lib,
  pkgs,
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

    systemd.services.n8n = {
      path = [pkgs.nodejs];
      environment = {
        N8N_SECURE_COOKIE = "false";
      };
    };
  };
}
