###############################################################################
# Zellij Terminal Multiplexer Module
# Configures the Zellij terminal multiplexer with custom themes and layouts
# - Custom theme configuration
# - Music layout for cmus and cava
# - Convenient shell aliases
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.modules.core.zsh.zellij;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.modules.core.zsh.zellij = {
    enable = lib.mkEnableOption "zellij terminal multiplexer";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Programs
    ###########################################################################
    programs.zellij = {
      enable = true;
      enableZshIntegration = true;

      settings = {
        theme = "dracula-custom";
        themes = {
          "dracula-custom" = {
            # Define UI components according to new theme specification
            ribbon_unselected = {
              base = "40 42 54";
              background = "68 71 90";
              emphasis_0 = "255 85 85";
              emphasis_1 = "248 248 242";
              emphasis_2 = "139 233 253";
              emphasis_3 = "255 121 198";
            };
            ribbon_selected = {
              base = "248 248 242";
              background = "98 114 164";
              emphasis_0 = "255 85 85";
              emphasis_1 = "248 248 242";
              emphasis_2 = "139 233 253";
              emphasis_3 = "255 121 198";
            };
            text_unselected = {
              base = "248 248 242";
              background = "40 42 54";
              emphasis_0 = "255 85 85";
              emphasis_1 = "80 250 123";
              emphasis_2 = "139 233 253";
              emphasis_3 = "255 121 198";
            };
            text_selected = {
              base = "248 248 242";
              background = "68 71 90";
              emphasis_0 = "255 85 85";
              emphasis_1 = "80 250 123";
              emphasis_2 = "139 233 253";
              emphasis_3 = "255 121 198";
            };
            table_title = {
              base = "248 248 242";
              background = "40 42 54";
              emphasis_0 = "255 85 85";
              emphasis_1 = "80 250 123";
              emphasis_2 = "139 233 253";
              emphasis_3 = "255 121 198";
            };
            table_cell_unselected = {
              base = "248 248 242";
              background = "40 42 54";
              emphasis_0 = "255 85 85";
              emphasis_1 = "80 250 123";
              emphasis_2 = "139 233 253";
              emphasis_3 = "255 121 198";
            };
            table_cell_selected = {
              base = "248 248 242";
              background = "68 71 90";
              emphasis_0 = "255 85 85";
              emphasis_1 = "80 250 123";
              emphasis_2 = "139 233 253";
              emphasis_3 = "255 121 198";
            };
            list_unselected = {
              base = "248 248 242";
              background = "40 42 54";
              emphasis_0 = "255 85 85";
              emphasis_1 = "80 250 123";
              emphasis_2 = "139 233 253";
              emphasis_3 = "255 121 198";
            };
            list_selected = {
              base = "248 248 242";
              background = "68 71 90";
              emphasis_0 = "255 85 85";
              emphasis_1 = "80 250 123";
              emphasis_2 = "139 233 253";
              emphasis_3 = "255 121 198";
            };
            frame_selected = {
              base = "98 114 164";
              background = "40 42 54";
              emphasis_0 = "255 85 85";
              emphasis_1 = "80 250 123";
              emphasis_2 = "139 233 253";
              emphasis_3 = "255 121 198";
            };
            frame_highlight = {
              base = "255 121 198";
              background = "40 42 54";
              emphasis_0 = "255 85 85";
              emphasis_1 = "80 250 123";
              emphasis_2 = "139 233 253";
              emphasis_3 = "255 121 198";
            };
            exit_code_success = {
              base = "80 250 123";
              background = "40 42 54";
              emphasis_0 = "255 85 85";
              emphasis_1 = "80 250 123";
              emphasis_2 = "139 233 253";
              emphasis_3 = "255 121 198";
            };
            exit_code_error = {
              base = "255 85 85";
              background = "40 42 54";
              emphasis_0 = "255 85 85";
              emphasis_1 = "80 250 123";
              emphasis_2 = "139 233 253";
              emphasis_3 = "255 121 198";
            };
            multiplayer_user_colors = {
              player_1 = "255 121 198";
              player_2 = "139 233 253";
              player_3 = "80 250 123";
              player_4 = "241 250 140";
              player_5 = "189 147 249";
              player_6 = "255 85 85";
              player_7 = "255 184 108";
              player_8 = "98 114 164";
              player_9 = "68 71 90";
              player_10 = "40 42 54";
            };
          };
        };

        # Pane frame settings
        hide_session_name = false;
        rounded_corners = true;
      };
    };

    ###########################################################################
    # Configuration Files
    ###########################################################################
    xdg.configFile."zellij/layouts/music.kdl".text = ''
      layout alias="music" {
          default_tab_template {
              pane size=1 borderless=true {
                  plugin location="zellij:tab-bar"
              }
              children
              pane size=2 borderless=true {
                  plugin location="zellij:status-bar"
              }
          }

          tab name="Music" {
              pane split_direction="vertical" {
                  pane command="cmus"
                  pane command="cava"
              }
          }
      }
    '';

    ###########################################################################
    # Shell Configuration
    ###########################################################################
    programs.zsh.shellAliases = {
      music = "zellij --layout music";
      # Kill all zellij sessions except the active one
      zk = "for session in $(zellij list-sessions | grep -v '(current)' | awk '{print $1}'); do zellij kill-session $session; done";
    };
  };
}
