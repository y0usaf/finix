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
        bg = "#1a1b26"; # dark background (Tokyo Night inspired)
        fg = "#c0caf5"; # soft white/blue foreground
        red = "#f7768e"; # soft red
        green = "#9ece6a"; # soft green
        blue = "#7aa2f7"; # soft blue
        yellow = "#e0af68"; # soft yellow
        magenta = "#bb9af7"; # soft purple
        orange = "#ff9e64"; # soft orange
        cyan = "#7dcfff"; # soft cyan
        black = "#24283b"; # slightly lighter black for contrast
        white = "#a9b1d6"; # soft white

        # Border colors - this controls the outline
        border_fg = "#7aa2f7"; # Change to blue instead of green
        border_bg = "#1a1b26"; # Match background
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
