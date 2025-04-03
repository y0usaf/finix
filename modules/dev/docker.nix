{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.dev.docker;
in {
  options.modules.dev.docker = {
    enable = mkEnableOption "docker development environment";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      docker
      docker-compose
      docker-buildx
      docker-credential-helpers
    ];

    # Add docker configuration
    home.file.".docker/config.json".text = builtins.toJSON {
      credsStore = "pass";
      currentContext = "default";
      plugins = {};
    };

    # Add docker aliases
    programs.zsh.shellAliases = {
      d = "docker";
      dc = "docker compose";
      dps = "docker ps";
      dpsa = "docker ps -a";
      di = "docker images";
      dex = "docker exec -it";
      dl = "docker logs";
      dlf = "docker logs -f";
      drm = "docker rm";
      drmi = "docker rmi";
    };
  };
}
