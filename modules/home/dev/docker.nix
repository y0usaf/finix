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
    users.users.${config.user.name}.maid = {
      packages = with pkgs; [
        docker
        docker-compose
        docker-buildx
        docker-credential-helpers
      ];
      file.home = {
        ".docker/config.json".text = builtins.toJSON {
          credsStore = "pass";
          currentContext = "default";
          plugins = {};
        };
      };
    };
  };
}
