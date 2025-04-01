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
        theme = "default";
        themes = {
          "foot" = {
            # Theme based on foot terminal colors
            bg = "#000000"; # Black background
            fg = "#ffffff"; # White foreground
            black = "#000000"; # Black
            red = "#ff0000"; # Red
            green = "#00ff00"; # Green
            yellow = "#ffff00"; # Yellow
            blue = "#1e90ff"; # Blue (dodger blue)
            magenta = "#ff00ff"; # Magenta
            cyan = "#00ffff"; # Cyan
            white = "#ffffff"; # White
            orange = "#ff8c00"; # Dark orange

            # Define UI components with Foot terminal colors
            ribbon_unselected = {
              bg = "#000000"; # Black
              fg = "#808080"; # Bright black
              base = "#ffffff"; # White
              emphasis_0 = "#ff0000"; # Red
              emphasis_1 = "#00ff00"; # Green
              emphasis_2 = "#ffff00"; # Yellow
              emphasis_3 = "#1e90ff"; # Blue
            };
            ribbon_selected = {
              bg = "#1e90ff"; # Blue
              fg = "#ffffff"; # White
              base = "#ffffff"; # White
              emphasis_0 = "#ff0000"; # Red
              emphasis_1 = "#00ff00"; # Green
              emphasis_2 = "#ffff00"; # Yellow
              emphasis_3 = "#ff00ff"; # Magenta
            };
            text_unselected = {
              bg = "#000000"; # Black
              fg = "#ffffff"; # White
              base = "#ffffff"; # White
              emphasis_0 = "#ff0000"; # Red
              emphasis_1 = "#00ff00"; # Green
              emphasis_2 = "#ffff00"; # Yellow
              emphasis_3 = "#1e90ff"; # Blue
            };
            text_selected = {
              bg = "#1e90ff"; # Blue
              fg = "#ffffff"; # White
              base = "#ffffff"; # White
              emphasis_0 = "#ff0000"; # Red
              emphasis_1 = "#00ff00"; # Green
              emphasis_2 = "#ffff00"; # Yellow
              emphasis_3 = "#ff00ff"; # Magenta
            };
            table_title = {
              bg = "#000000"; # Black
              fg = "#ffffff"; # White
              base = "#ffffff"; # White
              emphasis_0 = "#ff0000"; # Red
              emphasis_1 = "#00ff00"; # Green
              emphasis_2 = "#ffff00"; # Yellow
              emphasis_3 = "#1e90ff"; # Blue
            };
            table_cell_unselected = {
              bg = "#000000"; # Black
              fg = "#ffffff"; # White
              base = "#ffffff"; # White
              emphasis_0 = "#ff0000"; # Red
              emphasis_1 = "#00ff00"; # Green
              emphasis_2 = "#ffff00"; # Yellow
              emphasis_3 = "#1e90ff"; # Blue
            };
            table_cell_selected = {
              bg = "#1e90ff"; # Blue
              fg = "#ffffff"; # White
              base = "#ffffff"; # White
              emphasis_0 = "#ff0000"; # Red
              emphasis_1 = "#00ff00"; # Green
              emphasis_2 = "#ffff00"; # Yellow
              emphasis_3 = "#ff00ff"; # Magenta
            };
            list_unselected = {
              bg = "#000000"; # Black
              fg = "#ffffff"; # White
              base = "#ffffff"; # White
              emphasis_0 = "#ff0000"; # Red
              emphasis_1 = "#00ff00"; # Green
              emphasis_2 = "#ffff00"; # Yellow
              emphasis_3 = "#1e90ff"; # Blue
            };
            list_selected = {
              bg = "#1e90ff"; # Blue
              fg = "#ffffff"; # White
              base = "#ffffff"; # White
              emphasis_0 = "#ff0000"; # Red
              emphasis_1 = "#00ff00"; # Green
              emphasis_2 = "#ffff00"; # Yellow
              emphasis_3 = "#ff00ff"; # Magenta
            };
            frame_selected = {
              bg = "#000000"; # Black
              fg = "#1e90ff"; # Blue
              base = "#1e90ff"; # Blue
              emphasis_0 = "#ff0000"; # Red
              emphasis_1 = "#00ff00"; # Green
              emphasis_2 = "#ffff00"; # Yellow
              emphasis_3 = "#ff00ff"; # Magenta
            };
            frame_highlight = {
              bg = "#000000"; # Black
              fg = "#ffff00"; # Yellow
              base = "#ffff00"; # Yellow
              emphasis_0 = "#ff0000"; # Red
              emphasis_1 = "#00ff00"; # Green
              emphasis_2 = "#1e90ff"; # Blue
              emphasis_3 = "#ff00ff"; # Magenta
            };
            exit_code_success = {
              bg = "#000000"; # Black
              fg = "#00ff00"; # Green
              base = "#00ff00"; # Green
              emphasis_0 = "#ff0000"; # Red
              emphasis_1 = "#ffff00"; # Yellow
              emphasis_2 = "#1e90ff"; # Blue
              emphasis_3 = "#ff00ff"; # Magenta
            };
            exit_code_error = {
              bg = "#000000"; # Black
              fg = "#ff0000"; # Red
              base = "#ff0000"; # Red
              emphasis_0 = "#ff0000"; # Red
              emphasis_1 = "#ffff00"; # Yellow
              emphasis_2 = "#1e90ff"; # Blue
              emphasis_3 = "#ff00ff"; # Magenta
            };
            multiplayer_user_colors = [
              "#ff0000" # Red (player 1)
              "#00ff00" # Green (player 2)
              "#ffff00" # Yellow (player 3)
              "#1e90ff" # Blue (player 4)
              "#ff00ff" # Magenta (player 5)
              "#00ffff" # Cyan (player 6)
              "#ffffff" # White (player 7)
              "#ff8c00" # Orange (player 8)
              "#808080" # Bright black (player 9)
              "#000000" # Black (player 10)
            ];
          };

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
