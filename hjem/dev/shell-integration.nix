###############################################################################
# Development Shell Integration Module
# Adds development-specific environment variables, aliases, and functions
###############################################################################
{
  config,
  lib,
  ...
}: let
  cfg = config.cfg.hjome.dev.shell-integration;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.hjome.dev.shell-integration = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable development shell integration";
    };
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    # Development-specific environment variables
    environment.sessionVariables = {
      DEVEL = "1";
      DEBUG = "1";
    };

    # Development shell functions and aliases
    files.".zshrc".text = lib.mkAfter ''
      # Development aliases
      alias dev="cd ~/Dev"
      alias build="nix build"
      alias dev-shell="nix develop"
      alias fmt="alejandra ."

      # Development functions
      mkdev() {
        mkdir -p ~/Dev/"$1"
        cd ~/Dev/"$1"
      }

      # Git development shortcuts
      alias gc="git commit"
      alias gp="git push"
      alias gl="git log --oneline"
      alias gs="git status"
    '';
  };
}
