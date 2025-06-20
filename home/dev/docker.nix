###############################################################################
# Docker Development Environment (Maid Version)
# Installs Docker tools and provides convenient aliases
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.dev.docker;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.home.dev.docker = {
    enable = lib.mkEnableOption "docker development environment";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Maid Configuration
    ###########################################################################
    users.users.y0usaf.maid = {
      packages = with pkgs; [
        docker
        docker-compose
        docker-buildx
        docker-credential-helpers
      ];

      ###########################################################################
      # Configuration Files
      ###########################################################################
      file.home = {
        # Docker configuration
        ".docker/config.json".text = builtins.toJSON {
          credsStore = "pass";
          currentContext = "default";
          plugins = {};
        };
      };
    };
  };
}
