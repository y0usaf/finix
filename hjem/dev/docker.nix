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
    };
  };
}