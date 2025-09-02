{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.shell.zellij;

  # Import local generators
  toKDL = import ../../../../lib/generators/toKDL.nix {inherit lib;};

  # Base zellij configuration
  baseConfig =
    {
      hide_session_name = false;
      default_shell = "zsh";
      copy_on_select = true;
      show_startup_tips = false;
      theme = "neon_dark";
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
          ".config/zellij/themes/neon-dark.kdl" = {
            clobber = true;
            text = ''
              themes {
                  neon_dark {
                      text_unselected {
                          base 180 180 180
                          background 15 15 15
                          emphasis_0 120 120 120
                          emphasis_1 140 140 140
                          emphasis_2 160 160 160
                          emphasis_3 100 100 100
                      }
                      text_selected {
                          base 255 255 255
                          background 25 25 25
                          emphasis_0 200 200 200
                          emphasis_1 220 220 220
                          emphasis_2 240 240 240
                          emphasis_3 180 180 180
                      }
                      ribbon_selected {
                          base 0 0 0
                          background 0 255 150
                          emphasis_0 20 20 20
                          emphasis_1 40 40 40
                          emphasis_2 60 60 60
                          emphasis_3 80 80 80
                      }
                      ribbon_unselected {
                          base 140 140 140
                          background 35 35 35
                          emphasis_0 100 100 100
                          emphasis_1 160 160 160
                          emphasis_2 120 120 120
                          emphasis_3 80 80 80
                      }
                      table_title {
                          base 0 255 150
                          background 0 0 0
                          emphasis_0 150 150 150
                          emphasis_1 120 120 120
                          emphasis_2 180 180 180
                          emphasis_3 100 100 100
                      }
                      table_cell_selected {
                          base 255 255 255
                          background 25 25 25
                          emphasis_0 200 200 200
                          emphasis_1 220 220 220
                          emphasis_2 240 240 240
                          emphasis_3 180 180 180
                      }
                      table_cell_unselected {
                          base 180 180 180
                          background 15 15 15
                          emphasis_0 120 120 120
                          emphasis_1 140 140 140
                          emphasis_2 160 160 160
                          emphasis_3 100 100 100
                      }
                      list_selected {
                          base 255 255 255
                          background 25 25 25
                          emphasis_0 200 200 200
                          emphasis_1 220 220 220
                          emphasis_2 240 240 240
                          emphasis_3 180 180 180
                      }
                      list_unselected {
                          base 180 180 180
                          background 15 15 15
                          emphasis_0 120 120 120
                          emphasis_1 140 140 140
                          emphasis_2 160 160 160
                          emphasis_3 100 100 100
                      }
                      frame_selected {
                          base 0 255 150
                          background 0 0 0
                          emphasis_0 150 150 150
                          emphasis_1 120 120 120
                          emphasis_2 100 100 100
                          emphasis_3 80 80 80
                      }
                      frame_highlight {
                          base 0 200 255
                          background 0 0 0
                          emphasis_0 0 150 200
                          emphasis_1 0 180 220
                          emphasis_2 0 220 255
                          emphasis_3 0 120 180
                      }
                      exit_code_success {
                          base 0 255 100
                          background 0 0 0
                          emphasis_0 0 200 80
                          emphasis_1 0 180 60
                          emphasis_2 0 255 120
                          emphasis_3 0 160 40
                      }
                      exit_code_error {
                          base 255 0 100
                          background 0 0 0
                          emphasis_0 200 0 80
                          emphasis_1 180 0 60
                          emphasis_2 255 0 120
                          emphasis_3 160 0 40
                      }
                      multiplayer_user_colors {
                          player_1 0 200 255
                          player_2 255 100 0
                          player_3 0 255 100
                          player_4 255 0 200
                          player_5 200 0 255
                          player_6 255 255 0
                          player_7 0 255 255
                          player_8 255 0 100
                          player_9 100 255 0
                          player_10 255 150 0
                      }
                  }
              }
            '';
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
