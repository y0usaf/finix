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
    environment.systemPackages = [
      pkgs.docker
      pkgs.docker-compose
      pkgs.docker-buildx
      pkgs.docker-credential-helpers
    ];
    manzil.users."${config.user.name}".files.".config/docker/config.json" = {
      text = builtins.toJSON {
        credsStore = "pass";
        currentContext = "default";
        plugins = {};
      };
    };
  };
}
