{
  config,
  lib,
  ...
}: let
  cfg = config.services.syncthing-proxy;
in {
  options.services.syncthing-proxy = {
    enable = lib.mkEnableOption "Syncthing reverse proxy via nginx";
    virtualHostName = lib.mkOption {
      type = lib.types.str;
      description = "Name of the nginx virtual host for syncthing proxy";
    };
  };

  config = lib.mkIf cfg.enable {
    services.nginx = {
      enable = true;
      virtualHosts.${cfg.virtualHostName} = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:8384";
          proxyWebsockets = true;
        };
      };
    };
  };
}
