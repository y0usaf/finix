{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.shell.zellij;

  # Import local generators
  generators = import ../../../../lib/generators {inherit lib;};
  toKDL = import ../../../../lib/generators/toKDL.nix {inherit lib;};

  # Base zellij configuration
  baseConfig =
    {
      hide_session_name = false;
      theme = "gruvbox-dark";
      default_shell = "zsh";
      copy_on_select = false;
    }
    // cfg.settings
    // lib.optionalAttrs cfg.performanceMode {
      # Optimization settings
      session_serialization = false;
      pane_viewport_serialization = false;
      scrollback_lines_to_serialize = 0;
    };
in {
  config = lib.mkIf cfg.enable {
    hjem.users.${config.user.name} = {
      packages = with pkgs; [
        zellij
      ];
      files =
        {
          ".config/zellij/config.kdl" = {
            clobber = true;
            text =
              toKDL.toKDL {} baseConfig
              + "\n\n// Using default keybindings for now\n";
          };
        }
        // lib.optionalAttrs cfg.autoStart {
          ".config/zsh/aliases/zellij.zsh" = {
            clobber = true;
            text = ''
              # Auto-start zellij if not already in a session
              if [[ -z "$ZELLIJ" && -z "$SSH_CONNECTION" && -z "$TMUX" ]]; then
                exec zellij
              fi
            '';
          };
        };
    };
  };
}
