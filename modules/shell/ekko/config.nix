{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (config.user.shell) ekko;
  inherit (ekko) package;
in {
  options.user.shell.ekko = {
    enable = lib.mkEnableOption "Ekko V2 terminal multiplexer";
    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Attach each interactive terminal to the shared Ekko session";
    };
  };

  config = lib.mkIf ekko.enable {
    environment.systemPackages = [package];
    manzil.users.${config.user.name}.files.".config/ekko/init.lisp".text = builtins.readFile ./init.lisp;

    # Last in the interactive rc: the outer shell becomes the client. Bare
    # `ekko` only prints usage; `attach` opens a view on the default
    # instance's workspace — a cold daemon creates it first (single
    # $SHELL -i pane), so no run/attach branch is needed. Clients attach
    # concurrently: each terminal gets its own view onto the same panes.
    # No exec, so a detach or a crash falls back to the shell instead of
    # closing the terminal.
    # The daemon sets EKKO_INSTANCE on every pane it spawns; EKKO_SESSION_NAME
    # was the v1 variable and is stripped from pane environments, but guard
    # on it anyway so a stale v1 daemon still blocks recursion.
    # Keep this POSIX-compatible for both rush and Bash development shells.
    user.shell.rcExtra = lib.mkIf ekko.autoStart (lib.mkOrder 1600 ''
      if [ -z "''${EKKO_INSTANCE:-}" ] && [ -z "''${EKKO_SESSION_NAME:-}" ] &&
         [ -z "''${SSH_CONNECTION:-}" ] && [ -z "''${TMUX:-}" ] &&
         [ -z "''${STY:-}" ] && [ "''${TERM:-}" != linux ] && [ -t 0 ] && [ -t 1 ]; then
        case "$(${pkgs.coreutils}/bin/readlink /proc/self/fd/0)" in
          /dev/tty[0-9]*) ;;
          *) ${package}/bin/ekko attach ;;
        esac
      fi
    '');
  };
}
