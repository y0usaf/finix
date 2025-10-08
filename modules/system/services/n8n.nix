{
  lib,
  pkgs,
  hostConfig,
  ...
}: {
  config = lib.mkIf (lib.attrByPath ["services" "n8n" "enable"] false hostConfig) {
    services.n8n = {
      enable = true;
      openFirewall = lib.attrByPath ["services" "n8n" "openFirewall"] false hostConfig;
      settings = lib.attrByPath ["services" "n8n" "settings"] {} hostConfig;
    };

    systemd.services.n8n = {
      path = [pkgs.nodejs];
      environment = {
        N8N_SECURE_COOKIE = "false";
      };
    };
  };
}
