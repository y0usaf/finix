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
        fg = "#d8d8d8"; # light gray foreground
        red = "#cc9999"; # soft pastel red
        green = "#99cc99"; # soft pastel green
        blue = "#9999cc"; # soft pastel blue
        yellow = "#cccc99"; # soft pastel yellow
        magenta = "#cc99cc"; # soft pastel magenta
        orange = "#ccaa88"; # soft pastel orange
        cyan = "#99cccc"; # soft pastel cyan
        black = "#303030"; # dark gray
        white = "#f0f0f0"; # off-white

        # Border colors
        border_fg = "#7a7a7a"; # medium gray border
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
