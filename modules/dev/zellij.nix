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
        bg = "#000000"; # black background (from foot)
        fg = "#111111"; # white foreground (from foot)
        red = "#ff0000"; # red (from foot)
        green = "#00ff00"; # green (from foot)
        blue = "#1e90ff"; # blue (from foot)
        yellow = "#ffff00"; # yellow (from foot)
        magenta = "#ff00ff"; # magenta (from foot)
        orange = "#ff5500"; # vibrant orange (not in foot, keeping this)
        cyan = "#00ffff"; # cyan (from foot)
        black = "#000000"; # black (from foot)
        white = "#333333"; # white (from foot)

        # Border colors
        border_fg = "#333333"; # white border
        border_bg = "#000000"; # black background
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
