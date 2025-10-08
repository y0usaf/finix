{
  config,
  lib,
  pkgs,
  ...
}: {
  options.home.dev.docker = {
    enable = lib.mkEnableOption "docker development environment";
  };
  config = lib.mkIf config.home.dev.docker.enable {
    environment.systemPackages = [
      pkgs.docker
      pkgs.docker-compose
      pkgs.docker-buildx
      pkgs.docker-credential-helpers
    ];
    usr = {
      files = {
        ".docker/config.json" = {
          clobber = true;
          text = builtins.toJSON {
            credsStore = "pass";
            currentContext = "default";
            plugins = {};
          };
        };
      };
    };
  };
}
