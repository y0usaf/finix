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
        theme = "custom";
        themes = {
          "custom" = {
            # Define UI components with clear color descriptions
            ribbon_unselected = {
              bg = "#44475a"; # Dark purple-gray
              fg = "#282a36"; # Dark background
              base = "#f8f8f2"; # Light foreground
              emphasis_0 = "#ff5555"; # Red
              emphasis_1 = "#f8f8f2"; # Light foreground
              emphasis_2 = "#8be9fd"; # Cyan
              emphasis_3 = "#ff79c6"; # Pink
            };
            ribbon_selected = {
              bg = "#6272a4"; # Brighter purple
              fg = "#f8f8f2"; # Light foreground
              base = "#f8f8f2"; # Light foreground
              emphasis_0 = "#ff5555"; # Red
              emphasis_1 = "#f8f8f2"; # Light foreground
              emphasis_2 = "#8be9fd"; # Cyan
              emphasis_3 = "#ff79c6"; # Pink
            };
            text_unselected = {
              bg = "#282a36"; # Dark background
              fg = "#f8f8f2"; # Light foreground
              base = "#f8f8f2"; # Light foreground
              emphasis_0 = "#ff5555"; # Red
              emphasis_1 = "#50fa7b"; # Green
              emphasis_2 = "#8be9fd"; # Cyan
              emphasis_3 = "#ff79c6"; # Pink
            };
            text_selected = {
              bg = "#44475a"; # Dark purple-gray
              fg = "#f8f8f2"; # Light foreground
              base = "#f8f8f2"; # Light foreground
              emphasis_0 = "#ff5555"; # Red
              emphasis_1 = "#50fa7b"; # Green
              emphasis_2 = "#8be9fd"; # Cyan
              emphasis_3 = "#ff79c6"; # Pink
            };
            table_title = {
              bg = "#282a36"; # Dark background
              fg = "#f8f8f2"; # Light foreground
              base = "#f8f8f2"; # Light foreground
              emphasis_0 = "#ff5555"; # Red
              emphasis_1 = "#50fa7b"; # Green
              emphasis_2 = "#8be9fd"; # Cyan
              emphasis_3 = "#ff79c6"; # Pink
            };
            table_cell_unselected = {
              bg = "#282a36"; # Dark background
              fg = "#f8f8f2"; # Light foreground
              base = "#f8f8f2"; # Light foreground
              emphasis_0 = "#ff5555"; # Red
              emphasis_1 = "#50fa7b"; # Green
              emphasis_2 = "#8be9fd"; # Cyan
              emphasis_3 = "#ff79c6"; # Pink
            };
            table_cell_selected = {
              bg = "#44475a"; # Dark purple-gray
              fg = "#f8f8f2"; # Light foreground
              base = "#f8f8f2"; # Light foreground
              emphasis_0 = "#ff5555"; # Red
              emphasis_1 = "#50fa7b"; # Green
              emphasis_2 = "#8be9fd"; # Cyan
              emphasis_3 = "#ff79c6"; # Pink
            };
            list_unselected = {
              bg = "#282a36"; # Dark background
              fg = "#f8f8f2"; # Light foreground
              base = "#f8f8f2"; # Light foreground
              emphasis_0 = "#ff5555"; # Red
              emphasis_1 = "#50fa7b"; # Green
              emphasis_2 = "#8be9fd"; # Cyan
              emphasis_3 = "#ff79c6"; # Pink
            };
            list_selected = {
              bg = "#44475a"; # Dark purple-gray
              fg = "#f8f8f2"; # Light foreground
              base = "#f8f8f2"; # Light foreground
              emphasis_0 = "#ff5555"; # Red
              emphasis_1 = "#50fa7b"; # Green
              emphasis_2 = "#8be9fd"; # Cyan
              emphasis_3 = "#ff79c6"; # Pink
            };
            frame_selected = {
              bg = "#282a36"; # Dark background
              fg = "#6272a4"; # Brighter purple
              base = "#6272a4"; # Brighter purple
              emphasis_0 = "#ff5555"; # Red
              emphasis_1 = "#50fa7b"; # Green
              emphasis_2 = "#8be9fd"; # Cyan
              emphasis_3 = "#ff79c6"; # Pink
            };
            frame_highlight = {
              bg = "#282a36"; # Dark background
              fg = "#ff79c6"; # Pink
              base = "#ff79c6"; # Pink
              emphasis_0 = "#ff5555"; # Red
              emphasis_1 = "#50fa7b"; # Green
              emphasis_2 = "#8be9fd"; # Cyan
              emphasis_3 = "#ff79c6"; # Pink
            };
            exit_code_success = {
              bg = "#282a36"; # Dark background
              fg = "#50fa7b"; # Green
              base = "#50fa7b"; # Green
              emphasis_0 = "#ff5555"; # Red
              emphasis_1 = "#50fa7b"; # Green
              emphasis_2 = "#8be9fd"; # Cyan
              emphasis_3 = "#ff79c6"; # Pink
            };
            exit_code_error = {
              bg = "#282a36"; # Dark background
              fg = "#ff5555"; # Red
              base = "#ff5555"; # Red
              emphasis_0 = "#ff5555"; # Red
              emphasis_1 = "#50fa7b"; # Green
              emphasis_2 = "#8be9fd"; # Cyan
              emphasis_3 = "#ff79c6"; # Pink
            };
            multiplayer_user_colors = [
              "#ff79c6" # Pink (player 1)
              "#8be9fd" # Cyan (player 2)
              "#50fa7b" # Green (player 3)
              "#f1fa8c" # Yellow (player 4)
              "#bd93f9" # Purple (player 5)
              "#ff5555" # Red (player 6)
              "#ffb86c" # Orange (player 7)
              "#6272a4" # Brighter purple (player 8)
              "#44475a" # Dark purple-gray (player 9)
              "#282a36" # Dark background (player 10)
            ];
          };
        };

        # Pane frame settings
        hide_session_name = false;
        rounded_corners = true;
        show_startup_tips = false;
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
