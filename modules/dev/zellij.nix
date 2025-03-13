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
      themes = {
        custom = {
          bg = "#000000"; # black background
          fg = "#ffffff"; # white foreground
          red = "#ff0000"; # regular1
          green = "#00ff00"; # regular2
          blue = "#1e90ff"; # regular4
          yellow = "#ffff00"; # regular3
          magenta = "#ff00ff"; # regular5
          orange = "#ff8c00"; # derived from palette
          cyan = "#00ffff"; # regular6
          black = "#000000"; # regular0
          white = "#ffffff"; # regular7
        };
      };
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
    zk = "zellij ka --exclude $(zellij list-sessions | grep '(current)' | awk '{print $1}')";
  };
}
