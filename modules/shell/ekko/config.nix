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
    manzil.users.${config.user.name}.files.".config/ekko/init.lisp".text =
      builtins.readFile ./init.lisp + "\n" + builtins.readFile "${flakeInputs.ekko}/examples/themes/xp.lisp";

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
