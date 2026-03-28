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
    bayt.users."${config.user.name}".files =
      lib.optionalAttrs (config.user.shell.zellij.autoStart && config.user.shell.zsh.enable) {
        ".config/zsh/zellij.zsh" = {
          clobber = true;
          text = (import ../../../../lib/shell/zellij/config.nix {inherit lib;}).shellIntegration;
        };
      }
      // lib.optionalAttrs (config.user.shell.zellij.autoStart && config.user.shell.nushell.enable) {
        ".config/nushell/zellij.nu" = {
          clobber = true;
          text = ''
            # Skip if already in a multiplexer or SSH session
            if ("ZELLIJ" in $env) or ("SSH_CONNECTION" in $env) or ("TMUX" in $env) { return }

            # Skip if in virtual console
            if ($env.TERM? | default "") == "linux" { return }

            exec zellij
          '';
        };
      };
  };
}
