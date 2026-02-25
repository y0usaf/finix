{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.user.shell.zellij.enable {
    environment.systemPackages = [
      pkgs.zellij
    ];

    # Wallust (core) manages zellij config files for dynamic theming
    # Only shell integration is managed here
    usr.files = lib.optionalAttrs (config.user.shell.zellij.autoStart && config.user.shell.zsh.enable) {
      ".config/zsh/zellij.zsh" = {
        clobber = true;
        text = (import ../../../../lib/shell/zellij/config.nix {inherit lib;}).shellIntegration;
      };
    };
  };
}
