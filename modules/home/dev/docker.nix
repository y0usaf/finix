{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.dev.docker;
in {
  options.home.dev.docker = {
    enable = lib.mkEnableOption "docker development environment";
  };
  config = lib.mkIf cfg.enable {
    usr = {
      packages = with pkgs; [
        docker
        docker-compose
        docker-buildx
        docker-credential-helpers
      ];
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
