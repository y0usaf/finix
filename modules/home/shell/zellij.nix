{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.shell.zellij;
  ideLayout = import ./zellij-ide.nix {inherit lib config;};
in {
  options.home.shell.zellij = {
    enable = lib.mkEnableOption "zellij terminal multiplexer";
    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Automatically start zellij when opening zsh";
    };
    layouts = {
      ide = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "IDE layout configuration";
      };
    };
  };
  config = lib.mkIf cfg.enable {
    hjem.users.${config.user.name} = {
      packages = with pkgs; [
        zellij
      ];
      files = {
        ".config/zellij/config.kdl" = {
          clobber = true;
          text = ''
            hide_session_name false
            on_force_close "quit"
            pane_frames true
            rounded_corners true
            session_serialization false
            show_startup_tips false
            simplified_ui false
          '';
        };
        ".config/zellij/layouts/music.kdl" = {
          clobber = true;
          text = ''
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
        };
        ".config/zellij/layouts/ide.kdl" = {
          clobber = true;
          text = ideLayout.home.shell.zellij.layouts.ide;
        };
        ".config/zellij/config-ide.kdl" = {
          clobber = true;
          text = ''
            hide_session_name false
            on_force_close "quit"
            pane_frames true
            rounded_corners true
            session_serialization false
            show_startup_tips false
            simplified_ui true
          '';
        };
        ".config/zsh/aliases/zellij.zsh" = {
          clobber = true;
          text = ''
            # Zellij aliases and functions
            alias zj="zellij"
            alias zja="zellij attach"
            alias zjl="zellij list-sessions"
            alias zjk="zellij kill-session"
            alias zjd="zellij delete-session"
            alias zji="zellij --layout ide"
            alias zjm="zellij --layout music"
            
            ${lib.optionalString cfg.autoStart ''
            # Auto-start zellij if not already running and not in special environments
            if [[ -z "$ZELLIJ" && -z "$SSH_CONNECTION" && "$TERM_PROGRAM" != "vscode" && -z "$NVIM" ]]; then
                exec zellij
            fi
            ''}
          '';
        };
      };
    };
  };
}
