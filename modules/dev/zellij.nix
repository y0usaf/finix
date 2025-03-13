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
        bg = "#121212"; # darker background
        fg = "#d8d8d2"; # muted grey-white for text
        red = "#ff5555"; # vibrant but slightly muted red
        green = "#50fa7b"; # vibrant green with blue undertone
        blue = "#bd93f9"; # purple-blue for vibrancy
        yellow = "#f1fa8c"; # softer yellow that's still vibrant
        magenta = "#ff79c6"; # bright pink-magenta
        orange = "#ffb86c"; # warm vibrant orange
        cyan = "#8be9fd"; # bright cyan with blue undertone
        black = "#1a1a1a"; # very dark, almost black
        white = "#a0a0a0"; # much more muted grey instead of white

        # Border colors
        border_fg = "#6272a4"; # subtle purple-blue border
        border_bg = "#1a1a1a"; # matching the new black
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
