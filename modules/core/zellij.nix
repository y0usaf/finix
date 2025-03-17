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
        theme = "custom";
        themes.custom = {
          bg = "#000000"; # even darker background
          fg = "#666666"; # muted blue-green tint for better contrast
          red = "#ff5555"; # vibrant but slightly muted red
          green = "#50fa7b"; # vibrant green with blue undertone
          blue = "#bd93f9"; # purple-blue for vibrancy
          yellow = "#f1fa8c"; # softer yellow that's still vibrant
          magenta = "#ff79c6"; # bright pink-magenta
          orange = "#ffb86c"; # warm vibrant orange
          cyan = "#8be9fd"; # bright cyan with blue undertone
          black = "#000000"; # pure black
          white = "#666666"; # slightly brighter grey for tabs and status elements

          # Border colors
          border_fg = "#6272a4"; # subtle purple-blue border
          border_bg = "#000000"; # matching the new black
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
