###############################################################################
# Development Shell Contributions
# Shows how other modules can add to shell configuration
###############################################################################
{
  config,
  lib,
  ...
}: let
  cfg = config.cfg.hjome.dev.shell-contrib;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.hjome.dev.shell-contrib = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable development shell contributions";
    };
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    # Contribute to environment variables
    environment.sessionVariables = {
      EDITOR = "code";
      BROWSER = "firefox";
    };

    # Development-specific aliases and functions
    files.".zshrc".text = lib.mkAfter ''
      # Development tool aliases
      alias code.="code ."
      alias idea.="idea ."

      # Project management functions
      proj() {
        if [[ -z "$1" ]]; then
          echo "Usage: proj <project-name>"
          return 1
        fi
        mkdir -p ~/Dev/"$1"
        cd ~/Dev/"$1"
        code .
      }
    '';
  };
}
