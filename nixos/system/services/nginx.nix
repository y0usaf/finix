{
  config,
  lib,
  ...
}: {
  config.services.nginx.recommendedProxySettings = lib.mkIf config.services.nginx.enable true;
}
