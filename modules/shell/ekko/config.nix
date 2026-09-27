{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  package = flakeInputs.ekko.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".cache/ekko"
    ".config/ekko"
  ];
  environment.systemPackages = [package];
  manzil.users.${config.user.name}.files.".config/ekko/init.lisp".text =
    builtins.readFile ./init.lisp + "\n" + builtins.readFile "${flakeInputs.ekko}/examples/themes/xp.lisp";

  user.shell.rcExtra = lib.mkOrder 1600 ''
    if [ -z "''${EKKO_INSTANCE:-}" ] && [ -z "''${EKKO_SESSION_NAME:-}" ] &&
       [ -z "''${SSH_CONNECTION:-}" ] && [ -z "''${TMUX:-}" ] &&
       [ -z "''${STY:-}" ] && [ "''${TERM:-}" != linux ] && [ -t 0 ] && [ -t 1 ]; then
      case "$(${pkgs.coreutils}/bin/readlink /proc/self/fd/0)" in
        /dev/tty[0-9]*) ;;
        *) ${package}/bin/ekko attach ;;
      esac
    fi
  '';
}
