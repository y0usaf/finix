{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (config.user.shell) ekko;
in {
  options.user.shell.ekko = {
    enable = lib.mkEnableOption "ekko terminal multiplexer";
    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Automatically attach an ekko session on shell startup";
    };
    open = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Route the WM terminal-spawn bind through ekko: with an attached
        client, request focus for that existing terminal; cold (no client),
        fall back to spawning the regular terminal. Read by the WM modules
        (tomoe).
      '';
    };
  };

  config = lib.mkIf ekko.enable {
    environment.systemPackages = [
      # The stock muxer + a small helper that first tries `ekko activate`,
      # then falls back to the regular terminal spawn when no client is
      # attached.
      flakeInputs.ekko.packages."${pkgs.stdenv.hostPlatform.system}".default
      (pkgs.writeShellScriptBin "ekko-activate-or-terminal" ''
        if ekko activate >/dev/null 2>&1; then
          exit 0
        fi
        exec ${config.user.defaults.terminal} "$@"
      '')
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
            if ("EKKO_SESSION_NAME" in $env) or ("SSH_CONNECTION" in $env) or ("TMUX" in $env) { return }

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
            [[ -n "$EKKO_SESSION_NAME" || -n "$SSH_CONNECTION" || -n "$TMUX" ]] && return

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
