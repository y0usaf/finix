{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.zellij = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      theme = "custom";
      themes.custom = {
        bg = "#1a1a1a"; # very dark gray background
        fg = "#d0d0d0"; # light gray foreground
        red = "#a0a0a0"; # gray (was red)
        green = "#c0c0c0"; # light gray (was green)
        blue = "#909090"; # medium gray (was blue)
        yellow = "#b0b0b0"; # gray (was yellow)
        magenta = "#808080"; # darker gray (was purple)
        orange = "#a8a8a8"; # gray (was orange)
        cyan = "#e0e0e0"; # very light gray (was cyan)
        black = "#303030"; # dark gray (was black)
        white = "#f0f0f0"; # off-white

        # Border colors
        border_fg = "#505050"; # medium gray border
        border_bg = "#1a1a1a"; # very dark gray background
      };

      # Pane frame settings
      hide_session_name = false;
      rounded_corners = true;
    };
  };

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

  # Add a zsh shell alias for the "music" layout as part of the zellij module.
  # When you type "music" in zsh, it will execute "zellij --layout music" to load your layout.
  programs.zsh.shellAliases = {
    music = "zellij --layout music";
    # Kill all zellij sessions except the active one
    zk = "for session in $(zellij list-sessions | grep -v '(current)' | awk '{print $1}'); do zellij kill-session $session; done";
  };
}
