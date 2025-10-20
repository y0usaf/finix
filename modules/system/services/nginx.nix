{
  config,
  lib,
  ...
}: {
  options.services.nginx-reverse-proxy = lib.mkEnableOption "Enable Nginx reverse proxy for Tailscale services";

  config = lib.mkIf config.services.nginx-reverse-proxy {
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;

      virtualHosts."forgejo" = {
        locations."/" = {
          proxyPass = "http://100.105.204.116:3000";
          proxyWebsockets = true;
        };
      };
    };
  };
}
