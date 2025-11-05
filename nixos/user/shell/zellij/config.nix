{
  config,
  lib,
  pkgs,
  genLib,
  ...
}:
{
  config = lib.mkIf config.user.shell.zellij.enable {
    environment.systemPackages = [
      pkgs.zellij
    ];
    usr.files =
      {
        ".config/zellij/config.kdl" = {
          clobber = false;
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
            + "\n\n// Using default keybindings for now\n"
            + (lib.optionalString (config.user.shell.zellij.zjstatusHints.enable or false) ''
              plugins {
                zjstatus-hints location="https://github.com/b0o/zjstatus-hints/releases/latest/download/zjstatus-hints.wasm" {
                  max_length ${toString config.user.shell.zellij.zjstatusHints.maxLength}
                  pipe_name "${config.user.shell.zellij.zjstatusHints.pipeName}"
                }
              }

              load_plugins {
                zjstatus-hints
              }
            '')
            + config.user.shell.zellij.themeConfig;
        };
      }
      // lib.optionalAttrs (config.user.shell.zellij.autoStart && config.user.shell.zsh.enable) {
        ".config/zsh/zellij.zsh" = {
          clobber = true;
          text = (import ../../../../lib/shell/zellij/config.nix { inherit lib; }).shellIntegration;
        };
      }
      // lib.optionalAttrs (config.user.shell.zellij.enable && config.user.shell.zellij.zjstatus.enable) {
        ".config/zellij/layouts/zjstatus.kdl" = {
          clobber = true;
          text = config.user.shell.zellij.zjstatus.layout;
        };
      };
  };
}
