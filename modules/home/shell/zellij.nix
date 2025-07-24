{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.shell.zellij;
  zshConfig = {
    zellij = {
      enable = false;
    };
  };
  ideLayout = import ./zellij-ide.nix {inherit lib;};
in {
  options.home.shell.zellij = {
    enable = lib.mkEnableOption "zellij terminal multiplexer";
    layouts = {
      ide = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "IDE layout configuration";
      };
    };
  };
  config = lib.mkIf cfg.enable {
    users.users.y0usaf.maid = {
      packages = with pkgs; [
        zellij
      ];
      file = {
        xdg_config = {
          "zellij/config.kdl".text = ''
            hide_session_name false
            on_force_close "quit"
            pane_frames true
            rounded_corners true
            session_serialization false
            show_startup_tips false
            simplified_ui false
          '';
          "zellij/layouts/music.kdl".text = ''
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
          "zellij/layouts/ide.kdl".text = ideLayout.home.shell.zellij.layouts.ide;
          "zellij/config-ide.kdl".text = ''
            hide_session_name false
            on_force_close "quit"
            pane_frames true
            rounded_corners true
            session_serialization false
            show_startup_tips false
            simplified_ui true
          '';
        };
        home."{{xdg_config_home}}/zsh/.zshrc".text = lib.mkBefore (lib.optionalString zshConfig.zellij.enable ''
          if [[ -z "$ZELLIJ" && -z "$SSH_CONNECTION" && "$TERM_PROGRAM" != "vscode" && -z "$NVIM" ]]; then
              exec zellij
          fi
        '');
      };
    };
  };
}
