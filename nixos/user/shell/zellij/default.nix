{
  config,
  lib,
  pkgs,
  genLib,
  ...
}: let
  zjstatusUrl = "https://github.com/dj95/zjstatus/releases/download/v0.21.1/zjstatus.wasm";
  zjstatusHintsUrl = "https://github.com/b0o/zjstatus-hints/releases/latest/download/zjstatus-hints.wasm";
  baseConfig = {
    hide_session_name = false;
    copy_on_select = true;
    show_startup_tips = false;
    on_force_close = "quit";
    session_serialization = false;
    pane_frames = true;
  };
  shellIntegration = ''
    # Skip if already in a multiplexer or SSH session (fast: variable checks only)
    [[ -n "$ZELLIJ" || -n "$SSH_CONNECTION" || -n "$TMUX" ]] && return

    # Skip if in virtual console
    # Fast path: TERM check (no subprocess)
    [[ "$TERM" == "linux" ]] && return

    # Robust fallback: device path check (minimal subprocess overhead)
    [[ $(readlink /proc/self/fd/0 2>/dev/null) =~ ^/dev/tty[0-9] ]] && return

    exec zellij
  '';
  themeData = import ../../../../lib/shell/zellij/theme.nix {};
  zjstatusData = import ../../../../lib/shell/zellij/zjstatus.nix {};
in {
  imports = [
    ../../../../lib/shell/zellij/default.nix
  ];

  config = lib.mkIf config.user.shell.zellij.enable {
    environment.systemPackages = [
      pkgs.zellij
    ];

    user.shell.zellij.themeConfig =
      "\n// Neon theme configuration\n"
      + genLib.toKDL themeData;

    user.shell.zellij.zjstatus.layout = lib.mkDefault ''
      layout {
        default_tab_template {
          pane size=1 borderless=true {
            ${zjstatusData.zjstatusTopBar}
          }
          children
          pane size=1 borderless=true {
            ${zjstatusData.zjstatusHintsBar}
          }
        }
      }
    '';

    usr.files =
      {
        ".config/zellij/config.kdl" = {
          clobber = false;
          text =
            genLib.toKDL (
              baseConfig
              // lib.optionalAttrs config.user.shell.zellij.zjstatus.enable {
                default_layout = "zjstatus";
              }
              // config.user.shell.zellij.settings
            )
            + "\n\n// Using default keybindings for now\n"
            + (lib.optionalString (config.user.shell.zellij.zjstatusHints.enable or false) ''
              plugins {
                zjstatus-hints location="${zjstatusHintsUrl}" {
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
          text = shellIntegration;
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
