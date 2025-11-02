{
  config,
  lib,
  pkgs,
  inputs,
  genLib,
  ...
}: {
  config = lib.mkIf config.user.shell.zellij.enable {
    home-manager.users.y0usaf =
      {
        programs.zellij = {
          enable = true;
          inherit (config.user.shell.zellij) package;
        };

        home.file.".config/zellij/config.kdl" = {
          text =
            genLib.toKDL (
              {
                hide_session_name = false;
                copy_on_select = true;
                show_startup_tips = false;
                on_force_close = "quit";
                session_serialization = false;
                pane_frames = true;
              }
              // lib.optionalAttrs config.user.shell.zellij.zjstatus.enable {
                default_layout = "zjstatus";
              }
              // config.user.shell.zellij.settings
            )
            + "\n\n"
            + (lib.optionalString (config.user.shell.zellij.zjstatusHints.enable or false) ''
                plugins {
                  zjstatus-hints location="file:${inputs.zjstatus-hints.packages.${pkgs.system}.default}/bin/zjstatus-hints.wasm" {
                    max_length ${toString (config.user.shell.zellij.zjstatusHints.maxLength or 0)}
                    pipe_name "${config.user.shell.zellij.zjstatusHints.pipeName or "zjstatus_hints"}"
                  }
                }

                load_plugins {
                  zjstatus-hints
                }
              '')
            + config.user.shell.zellij.themeConfig;
        };
      }
      // lib.optionalAttrs config.user.shell.zellij.autoStart {
        home.file.".config/zsh/init-zellij.zsh" = {
          text = ''
            if [[ -z "$ZELLIJ" && -z "$SSH_CONNECTION" && -z "$TMUX" ]]; then
              exec zellij
            fi
          '';
        };

        programs.zsh.initContent = lib.mkAfter ''
          [[ -f "$XDG_CONFIG_HOME/zsh/init-zellij.zsh" ]] && source "$XDG_CONFIG_HOME/zsh/init-zellij.zsh"
        '';
      };
  };
}
