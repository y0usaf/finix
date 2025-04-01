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
            # Minimalist monochromatic theme with subtle shades of gray
            bg = "#1a1a1a"; # Dark background
            fg = "#d0d0d0"; # Light foreground
            black = "#1a1a1a"; # Base black
            red = "#a0a0a0"; # Light gray (replacing red)
            green = "#b0b0b0"; # Light gray (replacing green)
            yellow = "#c0c0c0"; # Light gray (replacing yellow)
            blue = "#909090"; # Gray (replacing blue)
            magenta = "#808080"; # Gray (replacing magenta)
            cyan = "#707070"; # Dark gray (replacing cyan)
            white = "#d0d0d0"; # Very light gray/almost white
            orange = "#a0a0a0"; # Same as red (for monochrome consistency)
            
            # Define UI components with clear color descriptions
            ribbon_unselected = {
              bg = "#404040"; # Medium-dark gray
              fg = "#1a1a1a"; # Very dark gray/black
              base = "#d0d0d0"; # Very light gray/almost white
              emphasis_0 = "#b0b0b0"; # Light gray
              emphasis_1 = "#d0d0d0"; # Very light gray/almost white
              emphasis_2 = "#909090"; # Gray
              emphasis_3 = "#707070"; # Dark gray
            };
            ribbon_selected = {
              bg = "#707070"; # Dark gray
              fg = "#d0d0d0"; # Very light gray/almost white
              base = "#d0d0d0"; # Very light gray/almost white
              emphasis_0 = "#b0b0b0"; # Light gray
              emphasis_1 = "#d0d0d0"; # Very light gray/almost white
              emphasis_2 = "#909090"; # Gray
              emphasis_3 = "#707070"; # Dark gray
            };
            text_unselected = {
              bg = "#1a1a1a"; # Very dark gray/black
              fg = "#d0d0d0"; # Very light gray/almost white
              base = "#d0d0d0"; # Very light gray/almost white
              emphasis_0 = "#b0b0b0"; # Light gray
              emphasis_1 = "#c0c0c0"; # Light gray
              emphasis_2 = "#909090"; # Gray
              emphasis_3 = "#707070"; # Dark gray
            };
            text_selected = {
              bg = "#404040"; # Medium-dark gray
              fg = "#d0d0d0"; # Very light gray/almost white
              base = "#d0d0d0"; # Very light gray/almost white
              emphasis_0 = "#b0b0b0"; # Light gray
              emphasis_1 = "#c0c0c0"; # Light gray
              emphasis_2 = "#909090"; # Gray
              emphasis_3 = "#707070"; # Dark gray
            };
            table_title = {
              bg = "#1a1a1a"; # Very dark gray/black
              fg = "#d0d0d0"; # Very light gray/almost white
              base = "#d0d0d0"; # Very light gray/almost white
              emphasis_0 = "#b0b0b0"; # Light gray
              emphasis_1 = "#c0c0c0"; # Light gray
              emphasis_2 = "#909090"; # Gray
              emphasis_3 = "#707070"; # Dark gray
            };
            table_cell_unselected = {
              bg = "#1a1a1a"; # Very dark gray/black
              fg = "#d0d0d0"; # Very light gray/almost white
              base = "#d0d0d0"; # Very light gray/almost white
              emphasis_0 = "#b0b0b0"; # Light gray
              emphasis_1 = "#c0c0c0"; # Light gray
              emphasis_2 = "#909090"; # Gray
              emphasis_3 = "#707070"; # Dark gray
            };
            table_cell_selected = {
              bg = "#404040"; # Medium-dark gray
              fg = "#d0d0d0"; # Very light gray/almost white
              base = "#d0d0d0"; # Very light gray/almost white
              emphasis_0 = "#b0b0b0"; # Light gray
              emphasis_1 = "#c0c0c0"; # Light gray
              emphasis_2 = "#909090"; # Gray
              emphasis_3 = "#707070"; # Dark gray
            };
            list_unselected = {
              bg = "#1a1a1a"; # Very dark gray/black
              fg = "#d0d0d0"; # Very light gray/almost white
              base = "#d0d0d0"; # Very light gray/almost white
              emphasis_0 = "#b0b0b0"; # Light gray
              emphasis_1 = "#c0c0c0"; # Light gray
              emphasis_2 = "#909090"; # Gray
              emphasis_3 = "#707070"; # Dark gray
            };
            list_selected = {
              bg = "#404040"; # Medium-dark gray
              fg = "#d0d0d0"; # Very light gray/almost white
              base = "#d0d0d0"; # Very light gray/almost white
              emphasis_0 = "#b0b0b0"; # Light gray
              emphasis_1 = "#c0c0c0"; # Light gray
              emphasis_2 = "#909090"; # Gray
              emphasis_3 = "#707070"; # Dark gray
            };
            frame_selected = {
              bg = "#1a1a1a"; # Very dark gray/black
              fg = "#707070"; # Dark gray
              base = "#707070"; # Dark gray
              emphasis_0 = "#b0b0b0"; # Light gray
              emphasis_1 = "#c0c0c0"; # Light gray
              emphasis_2 = "#909090"; # Gray
              emphasis_3 = "#707070"; # Dark gray
            };
            frame_highlight = {
              bg = "#1a1a1a"; # Very dark gray/black
              fg = "#c0c0c0"; # Light gray
              base = "#c0c0c0"; # Light gray
              emphasis_0 = "#b0b0b0"; # Light gray
              emphasis_1 = "#c0c0c0"; # Light gray
              emphasis_2 = "#909090"; # Gray
              emphasis_3 = "#707070"; # Dark gray
            };
            exit_code_success = {
              bg = "#1a1a1a"; # Very dark gray/black
              fg = "#c0c0c0"; # Light gray
              base = "#c0c0c0"; # Light gray
              emphasis_0 = "#b0b0b0"; # Light gray
              emphasis_1 = "#c0c0c0"; # Light gray
              emphasis_2 = "#909090"; # Gray
              emphasis_3 = "#707070"; # Dark gray
            };
            exit_code_error = {
              bg = "#1a1a1a"; # Very dark gray/black
              fg = "#b0b0b0"; # Light gray
              base = "#b0b0b0"; # Light gray
              emphasis_0 = "#b0b0b0"; # Light gray
              emphasis_1 = "#c0c0c0"; # Light gray
              emphasis_2 = "#909090"; # Gray
              emphasis_3 = "#707070"; # Dark gray
            };
            multiplayer_user_colors = [
              "#d0d0d0" # Very light gray (player 1)
              "#c0c0c0" # Light gray (player 2)
              "#b0b0b0" # Light gray (player 3)
              "#a0a0a0" # Gray (player 4)
              "#909090" # Gray (player 5)
              "#808080" # Medium gray (player 6)
              "#707070" # Dark gray (player 7)
              "#606060" # Dark gray (player 8)
              "#404040" # Very dark gray (player 9)
              "#1a1a1a" # Black/very dark gray (player 10)
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
