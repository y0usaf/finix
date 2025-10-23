{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.services.n8n.enable {
    systemd.services.n8n = {
      path = [pkgs.nodejs];
      environment = {
        N8N_SECURE_COOKIE = "false";
      };
    };
  };
}
