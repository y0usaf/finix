{
  lib,
  pkgs,
  flakeInputs,
  inputPackages,
  generators,
  ...
}: {
  user = {
    persist.directories = [
      ".cache/ekko"
      ".config/ekko"
    ];

    dev.prompts.host = ["`EKKO_INSTANCE` in your environment points at the ekko instance holding the live terminals."];

    files.".config/ekko/init.lisp".text =
      lib.removeSuffix "\n" (generators.lisp.render (import ./init.data.nix generators.lisp))
      + "\n"
      + builtins.readFile "${flakeInputs.ekko}/examples/themes/xp.lisp"
      + "\n(ekko/extensions:set-option :component ':xp :name :ground :value nil)\n";

    shell.rcExtra = lib.mkOrder 1600 ''
      if [ -z "''${EKKO_INSTANCE:-}" ] && [ -z "''${EKKO_SESSION_NAME:-}" ] &&
         [ -z "''${SSH_CONNECTION:-}" ] && [ -z "''${TMUX:-}" ] &&
         [ -z "''${STY:-}" ] && [ -z "''${TERN_PANE:-}" ] &&
         [ "''${TERM:-}" != linux ] && [ -t 0 ] && [ -t 1 ]; then
        case "$(${pkgs.coreutils}/bin/readlink /proc/self/fd/0)" in
          /dev/tty[0-9]*) ;;
          *) ${inputPackages.ekko.default}/bin/ekko attach ;;
        esac
      fi
    '';
  };

  environment.systemPackages = [inputPackages.ekko.default];
}
