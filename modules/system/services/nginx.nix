{
  config,
  lib,
  ...
}: {
  options.services.nginx-reverse-proxy = {
    enable = lib.mkEnableOption "Enable Nginx reverse proxy for Tailscale services";
    virtualHosts = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = {};
      description = "Virtual hosts configuration for reverse proxying to Tailscale services";
    };
  };

  config = lib.mkIf config.services.nginx-reverse-proxy.enable {
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      virtualHosts = config.services.nginx-reverse-proxy.virtualHosts;
    };
  };
}
