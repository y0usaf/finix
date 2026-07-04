{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  ekko = config.user.shell.ekko;
in {
  options.user.shell.ekko = {
    enable = lib.mkEnableOption "ekko terminal multiplexer";
    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Automatically attach an ekko session on shell startup";
    };
  };

  config = lib.mkIf ekko.enable {
    environment.systemPackages = [
      flakeInputs.ekko.packages."${pkgs.stdenv.hostPlatform.system}".default
    ];

    manzil.users."${config.user.name}".files =
      lib.optionalAttrs (ekko.autoStart && lib.attrByPath ["user" "shell" "nushell" "enable"] false config) {
        ".config/nushell/config.nu" = {
          text = lib.mkAfter ''
            source ~/.config/nushell/ekko.nu
          '';
        };
        ".config/nushell/ekko.nu" = {
          text = ''
            # Skip if already in a multiplexer or SSH session
            if ("EKKO_SESSION_NAME" in $env) or ("ZELLIJ" in $env) or ("SSH_CONNECTION" in $env) or ("TMUX" in $env) { return }

            # Skip if in virtual console
            if ($env.TERM? | default "") == "linux" { return }

            exec ekko
          '';
        };
      }
      // lib.optionalAttrs (ekko.autoStart && lib.attrByPath ["user" "shell" "zsh" "enable"] false config) {
        ".config/zsh/.zshrc" = {
          text = lib.mkAfter ''
            source "$ZDOTDIR/ekko.zsh"
          '';
        };
        ".config/zsh/ekko.zsh" = {
          text = ''
            # Skip if already in a multiplexer or SSH session (fast: variable checks only)
            [[ -n "$EKKO_SESSION_NAME" || -n "$ZELLIJ" || -n "$SSH_CONNECTION" || -n "$TMUX" ]] && return

            # Skip if in virtual console
            [[ "$TERM" == "linux" ]] && return

            # Robust fallback: device path check (minimal subprocess overhead)
            [[ $(readlink /proc/self/fd/0 2>/dev/null) =~ ^/dev/tty[0-9] ]] && return

            exec ekko
          '';
        };
      };
  };
}
