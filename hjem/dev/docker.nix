###############################################################################
# Docker Development Environment (Hjem Version)
# Installs Docker tools and provides convenient aliases
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.cfg.hjome.dev.docker;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.hjome.dev.docker = {
    enable = lib.mkEnableOption "docker development environment";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    packages = with pkgs; [
      docker
      docker-compose
      docker-buildx
      docker-credential-helpers
    ];

    ###########################################################################
    # Configuration Files
    ###########################################################################
    files = {
      # Docker configuration
      ".docker/config.json".text = builtins.toJSON {
        credsStore = "pass";
        currentContext = "default";
        plugins = {};
      };

      # Shell integration with Docker aliases
      ".zshrc".text = ''
        # Docker aliases
        alias d="docker"
        alias dc="docker compose"
        alias dps="docker ps"
        alias dpsa="docker ps -a"
        alias di="docker images"
        alias dex="docker exec -it"
        alias dl="docker logs"
        alias dlf="docker logs -f"
        alias drm="docker rm"
        alias drmi="docker rmi"
      '';
    };
  };
}
