{
  lib,
  hostConfig,
  ...
}: let
  cfg = hostConfig.services.n8n or {};
  defaultSettings = {
    N8N_SECURE_COOKIE = "false";
  };
in {
  config = lib.mkIf (cfg.enable or false) {
    services.n8n = {
      enable = true;
      openFirewall = cfg.openFirewall or false;
      settings = defaultSettings // (cfg.settings or {});
    };
  };
}
