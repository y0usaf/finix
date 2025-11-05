{
  config,
  lib,
  pkgs,
  genLib,
  ...
}: let
  cfg = import ../../../../lib/shell/zellij/config.nix { inherit lib; };
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
      + genLib.toKDL cfg.theme;

    user.shell.zellij.zjstatus.layout = lib.mkDefault ''
      layout {
        default_tab_template {
          pane size=1 borderless=true {
            ${cfg.zjstatus.zjstatusTopBar}
          }
          children
          pane size=1 borderless=true {
            ${cfg.zjstatus.zjstatusHintsBar}
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
              cfg.baseConfig
              // lib.optionalAttrs config.user.shell.zellij.zjstatus.enable {
                default_layout = "zjstatus";
              }
              // config.user.shell.zellij.settings
            )
            + "\n\n// Using default keybindings for now\n"
            + (lib.optionalString (config.user.shell.zellij.zjstatusHints.enable or false) ''
              plugins {
                zjstatus-hints location="${cfg.zjstatusHintsUrl}" {
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
          text = cfg.shellIntegration;
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
