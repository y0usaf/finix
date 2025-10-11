{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  # Import local generators
  toKDL = import ../../../../lib/generators/toKDL.nix {inherit lib;};

  # Base zellij configuration
  baseConfig =
    {
      hide_session_name = false;
      default_shell = "zsh";
      copy_on_select = true;
      show_startup_tips = false;
      on_force_close = "quit";
      session_serialization = false;
      pane_frames = true;
    }
    // lib.optionalAttrs config.user.shell.zellij.zjstatus.enable {
      default_layout = "zjstatus";
    }
    // config.user.shell.zellij.settings;

  zjstatusHintsConfig = "";
in {
  config = lib.mkIf config.user.shell.zellij.enable {
    environment.systemPackages = [
      pkgs.zellij
    ];
    usr = {
      files =
        {
          ".config/zellij/config.kdl" = {
            clobber = false;
            text =
              toKDL.toKDL {} baseConfig
              + "\n\n// Using default keybindings for now\n"
              + zjstatusHintsConfig;
          };
        }
        // lib.optionalAttrs config.user.shell.zellij.autoStart {
          ".config/zsh/aliases/zellij.zsh" = {
            clobber = true;
            text = ''
              # Auto-start zellij if not already in a session and not in TTY
              if [[ -z "$ZELLIJ" && -z "$SSH_CONNECTION" && -z "$TMUX" && ! "$TERM" =~ ^(linux|console)$ ]]; then
                exec zellij
              fi
            '';
          };
        };
    };
  };
}
