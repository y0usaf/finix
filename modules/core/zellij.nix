###############################################################################
# Zellij Terminal Multiplexer Module
# Configures the Zellij terminal multiplexer with custom themes and layouts
# - Custom theme configuration
# - Music layout for cmus and cava
# - Convenient shella aliases
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
              bg = "#44475a"; # background
              fg = "#282a36"; # foreground
              base = "#f8f8f2"; # base (required property)
              emphasis_0 = "#ff5555"; # emphasis_0
              emphasis_1 = "#f8f8f2"; # emphasis_1
              emphasis_2 = "#8be9fd"; # emphasis_2
              emphasis_3 = "#ff79c6"; # emphasis_3
            };
            ribbon_selected = {
              bg = "#6272a4"; # background
              fg = "#f8f8f2"; # foreground
              base = "#f8f8f2"; # base (required property)
              emphasis_0 = "#ff5555"; # emphasis_0
              emphasis_1 = "#f8f8f2"; # emphasis_1
              emphasis_2 = "#8be9fd"; # emphasis_2
              emphasis_3 = "#ff79c6"; # emphasis_3
            };
            text_unselected = {
              bg = "#282a36"; # background
              fg = "#f8f8f2"; # foreground
              base = "#f8f8f2"; # base (required property)
              emphasis_0 = "#ff5555"; # emphasis_0
              emphasis_1 = "#50fa7b"; # emphasis_1
              emphasis_2 = "#8be9fd"; # emphasis_2
              emphasis_3 = "#ff79c6"; # emphasis_3
            };
            text_selected = {
              bg = "#44475a"; # background
              fg = "#f8f8f2"; # foreground
              base = "#f8f8f2"; # base (required property)
              emphasis_0 = "#ff5555"; # emphasis_0
              emphasis_1 = "#50fa7b"; # emphasis_1
              emphasis_2 = "#8be9fd"; # emphasis_2
              emphasis_3 = "#ff79c6"; # emphasis_3
            };
            table_title = {
              bg = "#282a36"; # background
              fg = "#f8f8f2"; # foreground
              base = "#f8f8f2"; # base (required property)
              emphasis_0 = "#ff5555"; # emphasis_0
              emphasis_1 = "#50fa7b"; # emphasis_1
              emphasis_2 = "#8be9fd"; # emphasis_2
              emphasis_3 = "#ff79c6"; # emphasis_3
            };
            table_cell_unselected = {
              bg = "#282a36"; # background
              fg = "#f8f8f2"; # foreground
              base = "#f8f8f2"; # base (required property)
              emphasis_0 = "#ff5555"; # emphasis_0
              emphasis_1 = "#50fa7b"; # emphasis_1
              emphasis_2 = "#8be9fd"; # emphasis_2
              emphasis_3 = "#ff79c6"; # emphasis_3
            };
            table_cell_selected = {
              bg = "#44475a"; # background
              fg = "#f8f8f2"; # foreground
              base = "#f8f8f2"; # base (required property)
              emphasis_0 = "#ff5555"; # emphasis_0
              emphasis_1 = "#50fa7b"; # emphasis_1
              emphasis_2 = "#8be9fd"; # emphasis_2
              emphasis_3 = "#ff79c6"; # emphasis_3
            };
            list_unselected = {
              bg = "#282a36"; # background
              fg = "#f8f8f2"; # foreground
              base = "#f8f8f2"; # base (required property)
              emphasis_0 = "#ff5555"; # emphasis_0
              emphasis_1 = "#50fa7b"; # emphasis_1
              emphasis_2 = "#8be9fd"; # emphasis_2
              emphasis_3 = "#ff79c6"; # emphasis_3
            };
            list_selected = {
              bg = "#44475a"; # background
              fg = "#f8f8f2"; # foreground
              base = "#f8f8f2"; # base (required property)
              emphasis_0 = "#ff5555"; # emphasis_0
              emphasis_1 = "#50fa7b"; # emphasis_1
              emphasis_2 = "#8be9fd"; # emphasis_2
              emphasis_3 = "#ff79c6"; # emphasis_3
            };
            frame_selected = {
              bg = "#282a36"; # background
              fg = "#6272a4"; # foreground
              base = "#6272a4"; # base (required property)
              emphasis_0 = "#ff5555"; # emphasis_0
              emphasis_1 = "#50fa7b"; # emphasis_1
              emphasis_2 = "#8be9fd"; # emphasis_2
              emphasis_3 = "#ff79c6"; # emphasis_3
            };
            frame_highlight = {
              bg = "#282a36"; # background
              fg = "#ff79c6"; # foreground
              base = "#ff79c6"; # base (required property)
              emphasis_0 = "#ff5555"; # emphasis_0
              emphasis_1 = "#50fa7b"; # emphasis_1
              emphasis_2 = "#8be9fd"; # emphasis_2
              emphasis_3 = "#ff79c6"; # emphasis_3
            };
            exit_code_success = {
              bg = "#282a36"; # background
              fg = "#50fa7b"; # foreground
              base = "#50fa7b"; # base (required property)
              emphasis_0 = "#ff5555"; # emphasis_0
              emphasis_1 = "#50fa7b"; # emphasis_1
              emphasis_2 = "#8be9fd"; # emphasis_2
              emphasis_3 = "#ff79c6"; # emphasis_3
            };
            exit_code_error = {
              bg = "#282a36"; # background
              fg = "#ff5555"; # foreground
              base = "#ff5555"; # base (required property)
              emphasis_0 = "#ff5555"; # emphasis_0
              emphasis_1 = "#50fa7b"; # emphasis_1
              emphasis_2 = "#8be9fd"; # emphasis_2
              emphasis_3 = "#ff79c6"; # emphasis_3
            };
            multiplayer_user_colors = [
              "#ff79c6" # player_1
              "#8be9fd" # player_2
              "#50fa7b" # player_3
              "#f1fa8c" # player_4
              "#bd93f9" # player_5
              "#ff5555" # player_6
              "#ffb86c" # player_7
              "#6272a4" # player_8
              "#44475a" # player_9
              "#282a36" # player_10
            ];
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
