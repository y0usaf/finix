{
  config,
  lib,
  pkgs,
  genLib,
  ...
}: let
  cfg = import ../../../../lib/shell/zellij/config.nix {inherit lib;};
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
              cfg.mkKdlAttrs {
                zjstatusEnabled = config.user.shell.zellij.zjstatus.enable;
                userSettings = config.user.shell.zellij.settings;
              }
            )
            + "\n\n// Using default keybindings for now\n"
            + cfg.mkPluginsString {
              zjstatusEnabled = config.user.shell.zellij.zjstatus.enable;
            }
            + genLib.toKDL cfg.theme;
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
