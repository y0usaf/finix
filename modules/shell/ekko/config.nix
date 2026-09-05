{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (config.user.shell) ekko;
  package = flakeInputs.ekko.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  options.user.shell.ekko = {
    enable = lib.mkEnableOption "Ekko V2 terminal multiplexer";
    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Start a new named Ekko session in each interactive terminal";
    };
  };

  config = lib.mkIf ekko.enable {
    environment.systemPackages = [package];
    manzil.users.${config.user.name}.files.".config/ekko/init.lisp".text = builtins.readFile ./init.lisp;

    # Last in the interactive rc: the outer shell becomes the client. The
    # daemon sets EKKO_SESSION_NAME for initial panes and subsequent splits.
    # Keep this POSIX-compatible for both rush and Bash development shells.
    user.shell.rcExtra = lib.mkIf ekko.autoStart (lib.mkOrder 1600 ''
      if [ -z "''${EKKO_SESSION_NAME:-}" ] && [ -z "''${SSH_CONNECTION:-}" ] &&
         [ -z "''${TMUX:-}" ] && [ -z "''${STY:-}" ] &&
         [ "''${TERM:-}" != linux ] && [ -t 0 ] && [ -t 1 ]; then
        case "$(${pkgs.coreutils}/bin/readlink /proc/self/fd/0)" in
          /dev/tty[0-9]*) ;;
          *) exec ${package}/bin/ekko run --session "terminal-$(${pkgs.coreutils}/bin/date +%s)-$$" "$SHELL" -i ;;
        esac
      fi
    '');
  };
}
