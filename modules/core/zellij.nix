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
        theme = "monochrome";
        themes = {
          "monochrome" = {
            # Enhanced monochromatic theme with better contrasts
            bg = "#1a1a1a"; # Dark background
            fg = "#e0e0e0"; # Light foreground (brighter for better contrast)
            black = "#1a1a1a"; # Base black
            red = "#e0e0e0"; # Almost white (for errors/critical elements)
            green = "#c8c8c8"; # Light gray (for success indicators)
            yellow = "#d4d4d4"; # Light gray (for warnings/highlights)
            blue = "#b0b0b0"; # Gray (for information)
            magenta = "#cccccc"; # Gray (for special elements)
            cyan = "#a8a8a8"; # Dark gray (for secondary elements)
            white = "#f0f0f0"; # Very light gray/almost white
            orange = "#dadada"; # Light gray (for attention elements)
            
            # Define UI components with clear color descriptions
            ribbon_unselected = {
              bg = "#404040"; # Medium-dark gray
              fg = "#f0f0f0"; # Very light gray/almost white
              base = "#e0e0e0"; # Light foreground
              emphasis_0 = "#e0e0e0"; # Almost white (for contrast)
              emphasis_1 = "#f0f0f0"; # Very light gray/almost white
              emphasis_2 = "#c8c8c8"; # Light gray
              emphasis_3 = "#a8a8a8"; # Dark gray
            };
            ribbon_selected = {
              bg = "#606060"; # Dark gray
              fg = "#f0f0f0"; # Very light gray/almost white
              base = "#f0f0f0"; # Very light gray/almost white
              emphasis_0 = "#e0e0e0"; # Almost white
              emphasis_1 = "#f0f0f0"; # Very light gray/almost white
              emphasis_2 = "#d4d4d4"; # Light gray
              emphasis_3 = "#cccccc"; # Light-medium gray
            };
            text_unselected = {
              bg = "#1a1a1a"; # Very dark gray/black
              fg = "#e0e0e0"; # Light foreground
              base = "#e0e0e0"; # Light foreground
              emphasis_0 = "#e0e0e0"; # Almost white (for contrast)
              emphasis_1 = "#d4d4d4"; # Light gray
              emphasis_2 = "#c8c8c8"; # Light gray
              emphasis_3 = "#b0b0b0"; # Medium gray
            };
            text_selected = {
              bg = "#303030"; # Medium-dark gray
              fg = "#f0f0f0"; # Very light gray/almost white
              base = "#f0f0f0"; # Very light gray/almost white
              emphasis_0 = "#e0e0e0"; # Almost white
              emphasis_1 = "#dadada"; # Light gray
              emphasis_2 = "#cccccc"; # Light-medium gray
              emphasis_3 = "#b0b0b0"; # Medium gray
            };
            table_title = {
              bg = "#1a1a1a"; # Very dark gray/black
              fg = "#f0f0f0"; # Very light gray/almost white
              base = "#f0f0f0"; # Very light gray/almost white
              emphasis_0 = "#e0e0e0"; # Almost white
              emphasis_1 = "#dadada"; # Light gray
              emphasis_2 = "#cccccc"; # Light-medium gray
              emphasis_3 = "#b0b0b0"; # Medium gray
            };
            table_cell_unselected = {
              bg = "#1a1a1a"; # Very dark gray/black
              fg = "#e0e0e0"; # Light foreground
              base = "#e0e0e0"; # Light foreground
              emphasis_0 = "#e0e0e0"; # Almost white
              emphasis_1 = "#d4d4d4"; # Light gray
              emphasis_2 = "#c8c8c8"; # Light gray
              emphasis_3 = "#b0b0b0"; # Medium gray
            };
            table_cell_selected = {
              bg = "#303030"; # Medium-dark gray
              fg = "#f0f0f0"; # Very light gray/almost white
              base = "#f0f0f0"; # Very light gray/almost white
              emphasis_0 = "#e0e0e0"; # Almost white
              emphasis_1 = "#dadada"; # Light gray
              emphasis_2 = "#cccccc"; # Light-medium gray
              emphasis_3 = "#b0b0b0"; # Medium gray
            };
            list_unselected = {
              bg = "#1a1a1a"; # Very dark gray/black
              fg = "#e0e0e0"; # Light foreground
              base = "#e0e0e0"; # Light foreground
              emphasis_0 = "#e0e0e0"; # Almost white
              emphasis_1 = "#d4d4d4"; # Light gray
              emphasis_2 = "#c8c8c8"; # Light gray
              emphasis_3 = "#b0b0b0"; # Medium gray
            };
            list_selected = {
              bg = "#303030"; # Medium-dark gray
              fg = "#f0f0f0"; # Very light gray/almost white
              base = "#f0f0f0"; # Very light gray/almost white
              emphasis_0 = "#e0e0e0"; # Almost white
              emphasis_1 = "#dadada"; # Light gray
              emphasis_2 = "#cccccc"; # Light-medium gray
              emphasis_3 = "#b0b0b0"; # Medium gray
            };
            frame_selected = {
              bg = "#1a1a1a"; # Very dark gray/black
              fg = "#cccccc"; # Light-medium gray
              base = "#cccccc"; # Light-medium gray
              emphasis_0 = "#e0e0e0"; # Almost white
              emphasis_1 = "#dadada"; # Light gray
              emphasis_2 = "#c8c8c8"; # Light gray
              emphasis_3 = "#b0b0b0"; # Medium gray
            };
            frame_highlight = {
              bg = "#1a1a1a"; # Very dark gray/black
              fg = "#f0f0f0"; # Very light gray/almost white
              base = "#f0f0f0"; # Very light gray/almost white
              emphasis_0 = "#e0e0e0"; # Almost white
              emphasis_1 = "#dadada"; # Light gray
              emphasis_2 = "#cccccc"; # Light-medium gray
              emphasis_3 = "#b0b0b0"; # Medium gray
            };
            exit_code_success = {
              bg = "#1a1a1a"; # Very dark gray/black
              fg = "#e0e0e0"; # Almost white
              base = "#e0e0e0"; # Almost white
              emphasis_0 = "#e0e0e0"; # Almost white
              emphasis_1 = "#dadada"; # Light gray
              emphasis_2 = "#cccccc"; # Light-medium gray
              emphasis_3 = "#b0b0b0"; # Medium gray
            };
            exit_code_error = {
              bg = "#1a1a1a"; # Very dark gray/black
              fg = "#f0f0f0"; # Very light gray/almost white
              base = "#f0f0f0"; # Very light gray/almost white
              emphasis_0 = "#e0e0e0"; # Almost white
              emphasis_1 = "#dadada"; # Light gray
              emphasis_2 = "#cccccc"; # Light-medium gray
              emphasis_3 = "#b0b0b0"; # Medium gray
            };
            multiplayer_user_colors = [
              "#f0f0f0" # Very light gray (player 1)
              "#e0e0e0" # Almost white (player 2)
              "#dadada" # Light gray (player 3)
              "#d4d4d4" # Light gray (player 4)
              "#cccccc" # Light-medium gray (player 5)
              "#c8c8c8" # Light gray (player 6)
              "#b0b0b0" # Medium gray (player 7)
              "#a8a8a8" # Medium gray (player 8)
              "#606060" # Dark gray (player 9)
              "#404040" # Very dark gray (player 10)
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
