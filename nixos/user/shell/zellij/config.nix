{
  config,
  lib,
  pkgs,
  genLib,
  ...
}: {
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
              (import ../../../../lib/shell/zellij/config.nix {inherit lib;}).mkKdlAttrs {
                zjstatusEnabled = config.user.shell.zellij.zjstatus.enable;
                userSettings = config.user.shell.zellij.settings;
              }
            )
            + "\n\n// Using default keybindings for now\n"
            + (import ../../../../lib/shell/zellij/config.nix {inherit lib;}).mkPluginsString {
              zjstatusEnabled = config.user.shell.zellij.zjstatus.enable;
            }
            + genLib.toKDL (import ../../../../lib/shell/zellij/config.nix {inherit lib;}).theme;
        };
      }
      // lib.optionalAttrs (config.user.shell.zellij.autoStart && config.user.shell.zsh.enable) {
        ".config/zsh/zellij.zsh" = {
          clobber = true;
          text = (import ../../../../lib/shell/zellij/config.nix {inherit lib;}).shellIntegration;
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
