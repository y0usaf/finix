{
  config,
  lib,
  pkgs,
  genLib,
  ...
}: let
  cfg = import ../../../../lib/shell/zellij/config.nix {inherit lib;};
  themeConfig = "\n// Neon theme configuration\n" + genLib.toKDL cfg.theme;
in {
  imports = [
    ../../../../lib/shell/zellij/default.nix
  ];

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
              cfg.baseConfig
              // lib.optionalAttrs config.user.shell.zellij.zjstatus.enable {
                default_layout = "zjstatus";
              }
              // config.user.shell.zellij.settings
            )
            + "\n\n// Using default keybindings for now\n"
            + (lib.optionalString config.user.shell.zellij.zjstatus.enable ''
              plugins {
                zjstatus-hints location="${cfg.zjstatusHintsUrl}" {
                  max_length 0
                  pipe_name "zjstatus_hints"
                }
              }

              load_plugins {
                zjstatus-hints
              }
            '')
            + themeConfig;
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
