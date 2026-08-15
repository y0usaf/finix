{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.dev.docker = {
    enable = lib.mkEnableOption "docker development environment";
  };
  config = lib.mkIf config.user.dev.docker.enable {
    # docker + docker-compose are filtered out by finix's compat shim (docker
    # is deployed via podman in hosts); docker-buildx and the credential
    # helpers survive the filter.
    environment.systemPackages = [
      pkgs.docker-buildx
      pkgs.docker-credential-helpers
    ];
    manzil.users."${config.user.name}".files.".config/docker/config.json" = {
      generator = lib.generators.toJSON {};
      value = {
        credsStore = "pass";
        currentContext = "default";
        plugins = {};
      };
    };
  };
}
