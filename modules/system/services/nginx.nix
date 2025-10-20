{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.services.nginx.enable {
    services.nginx.recommendedProxySettings = true;
  };
}
