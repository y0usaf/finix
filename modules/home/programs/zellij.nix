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
  cfg = config.cfg.core.zsh.zellij;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.core.zsh.zellij = {
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
            # Gruvbox theme colors
            bg = "#282828"; # Dark background
            fg = "#ebdbb2"; # Light foreground
            black = "#282828"; # Black
            red = "#cc241d"; # Red
            green = "#98971a"; # Green
            yellow = "#d79921"; # Yellow
            blue = "#458588"; # Blue
            magenta = "#b16286"; # Magenta
            cyan = "#689d6a"; # Cyan
            white = "#ebdbb2"; # White/Cream
            orange = "#d65d0e"; # Orange

            # Define UI components with Gruvbox colors
            ribbon_unselected = {
              bg = "#3c3836"; # Dark gray
              fg = "#a89984"; # Gray/Medium foreground
              base = "#ebdbb2"; # Light foreground
              emphasis_0 = "#cc241d"; # Red
              emphasis_1 = "#ebdbb2"; # Light foreground
              emphasis_2 = "#689d6a"; # Cyan
              emphasis_3 = "#d65d0e"; # Orange
            };
            ribbon_selected = {
              bg = "#458588"; # Blue
              fg = "#ebdbb2"; # Light foreground
              base = "#ebdbb2"; # Light foreground
              emphasis_0 = "#cc241d"; # Red
              emphasis_1 = "#ebdbb2"; # Light foreground
              emphasis_2 = "#689d6a"; # Cyan
              emphasis_3 = "#d65d0e"; # Orange
            };
            text_unselected = {
              bg = "#282828"; # Dark background
              fg = "#ebdbb2"; # Light foreground
              base = "#ebdbb2"; # Light foreground
              emphasis_0 = "#cc241d"; # Red
              emphasis_1 = "#98971a"; # Green
              emphasis_2 = "#689d6a"; # Cyan
              emphasis_3 = "#d65d0e"; # Orange
            };
            text_selected = {
              bg = "#3c3836"; # Dark gray
              fg = "#ebdbb2"; # Light foreground
              base = "#ebdbb2"; # Light foreground
              emphasis_0 = "#cc241d"; # Red
              emphasis_1 = "#98971a"; # Green
              emphasis_2 = "#689d6a"; # Cyan
              emphasis_3 = "#d65d0e"; # Orange
            };
            table_title = {
              bg = "#282828"; # Dark background
              fg = "#ebdbb2"; # Light foreground
              base = "#ebdbb2"; # Light foreground
              emphasis_0 = "#cc241d"; # Red
              emphasis_1 = "#98971a"; # Green
              emphasis_2 = "#689d6a"; # Cyan
              emphasis_3 = "#d65d0e"; # Orange
            };
            table_cell_unselected = {
              bg = "#282828"; # Dark background
              fg = "#ebdbb2"; # Light foreground
              base = "#ebdbb2"; # Light foreground
              emphasis_0 = "#cc241d"; # Red
              emphasis_1 = "#98971a"; # Green
              emphasis_2 = "#689d6a"; # Cyan
              emphasis_3 = "#d65d0e"; # Orange
            };
            table_cell_selected = {
              bg = "#3c3836"; # Dark gray
              fg = "#ebdbb2"; # Light foreground
              base = "#ebdbb2"; # Light foreground
              emphasis_0 = "#cc241d"; # Red
              emphasis_1 = "#98971a"; # Green
              emphasis_2 = "#689d6a"; # Cyan
              emphasis_3 = "#d65d0e"; # Orange
            };
            list_unselected = {
              bg = "#282828"; # Dark background
              fg = "#ebdbb2"; # Light foreground
              base = "#ebdbb2"; # Light foreground
              emphasis_0 = "#cc241d"; # Red
              emphasis_1 = "#98971a"; # Green
              emphasis_2 = "#689d6a"; # Cyan
              emphasis_3 = "#d65d0e"; # Orange
            };
            list_selected = {
              bg = "#3c3836"; # Dark gray
              fg = "#ebdbb2"; # Light foreground
              base = "#ebdbb2"; # Light foreground
              emphasis_0 = "#cc241d"; # Red
              emphasis_1 = "#98971a"; # Green
              emphasis_2 = "#689d6a"; # Cyan
              emphasis_3 = "#d65d0e"; # Orange
            };
            frame_selected = {
              bg = "#282828"; # Dark background
              fg = "#458588"; # Blue
              base = "#458588"; # Blue
              emphasis_0 = "#cc241d"; # Red
              emphasis_1 = "#98971a"; # Green
              emphasis_2 = "#689d6a"; # Cyan
              emphasis_3 = "#d65d0e"; # Orange
            };
            frame_highlight = {
              bg = "#282828"; # Dark background
              fg = "#d79921"; # Yellow
              base = "#d79921"; # Yellow
              emphasis_0 = "#cc241d"; # Red
              emphasis_1 = "#98971a"; # Green
              emphasis_2 = "#689d6a"; # Cyan
              emphasis_3 = "#d65d0e"; # Orange
            };
            exit_code_success = {
              bg = "#282828"; # Dark background
              fg = "#98971a"; # Green
              base = "#98971a"; # Green
              emphasis_0 = "#cc241d"; # Red
              emphasis_1 = "#98971a"; # Green
              emphasis_2 = "#689d6a"; # Cyan
              emphasis_3 = "#d65d0e"; # Orange
            };
            exit_code_error = {
              bg = "#282828"; # Dark background
              fg = "#cc241d"; # Red
              base = "#cc241d"; # Red
              emphasis_0 = "#cc241d"; # Red
              emphasis_1 = "#98971a"; # Green
              emphasis_2 = "#689d6a"; # Cyan
              emphasis_3 = "#d65d0e"; # Orange
            };
            multiplayer_user_colors = [
              "#cc241d" # Red (player 1)
              "#98971a" # Green (player 2)
              "#d79921" # Yellow (player 3)
              "#458588" # Blue (player 4)
              "#b16286" # Magenta (player 5)
              "#689d6a" # Cyan (player 6)
              "#ebdbb2" # White/Cream (player 7)
              "#d65d0e" # Orange (player 8)
              "#a89984" # Gray (player 9)
              "#3c3836" # Dark gray (player 10)
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
