{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.finix.persistence.bindReplay;
  user = config.user.name;
  home = config.user.homeDirectory;
  persistentHome = "${cfg.root}/home/${user}";
  directoriesFile = pkgs.writeText "persist-user-directories" (lib.concatMapStrings (path: "${path}\n") cfg.directories);
  filesFile = pkgs.writeText "persist-user-files" (lib.concatMapStrings (path: "${path}\n") cfg.files);
in {
  options.finix.persistence.bindReplay = {
    enable = lib.mkEnableOption "Finix user persistence bind replay";
    root = lib.mkOption {
      type = lib.types.str;
      default = "/persist";
      description = "Root of persistent system state.";
    };
    group = lib.mkOption {
      type = lib.types.str;
      default = "users";
      description = "Primary group used for persistent user paths.";
    };
    directories = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Home-relative directories replayed as bind mounts.";
    };
    files = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Home-relative files replayed as bind mounts.";
    };
    bindRoot = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Bind the persistent root home onto /root.";
    };
  };

  config = lib.mkIf cfg.enable {
    finit.tasks.persist-user-binds = {
      description = "replay the user persistence allowlist as bind mounts";
      command = "${pkgs.writeShellScript "persist-user-binds" ''
        set -u
        export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.util-linux]}

        for _ in $(seq 1 120); do
          mountpoint -q ${cfg.root} && mountpoint -q /home && break
          sleep 1
        done
        mountpoint -q ${cfg.root} || { echo "persist-user-binds: ${cfg.root} never mounted" >&2; exit 1; }
        mountpoint -q /home || { echo "persist-user-binds: /home never mounted" >&2; exit 1; }

        install -d -m 0700 -o ${user} -g ${cfg.group} ${home}
        install -d -m 0755 ${persistentHome}
        chown ${user}:${cfg.group} ${home} || true

        ensure_parents() {
          base="$1"
          relative="$2"
          parent="''${relative%/*}"
          [ "$parent" = "$relative" ] && return 0
          rest="$parent"
          built=""
          while [ -n "$rest" ]; do
            case "$rest" in
              */*) component="''${rest%%/*}"; rest="''${rest#*/}" ;;
              *) component="$rest"; rest="" ;;
            esac
            [ -n "$built" ] && built="$built/$component" || built="$component"
            directory="$base/$built"
            if [ -d "$directory" ]; then
              chown ${user}:${cfg.group} "$directory" || true
            else
              install -d -m 0755 -o ${user} -g ${cfg.group} "$directory" || true
            fi
          done
        }

        failed=0
        ${lib.optionalString cfg.bindRoot ''
          install -d -m 0700 ${cfg.root}/root
          install -d -m 0700 /root
          mountpoint -q /root || mount --bind ${cfg.root}/root /root || failed=1
        ''}

        while IFS= read -r relative; do
          [ -n "$relative" ] || continue
          src="${persistentHome}/$relative"
          dst="${home}/$relative"
          ensure_parents ${persistentHome} "$relative"
          ensure_parents ${home} "$relative"
          [ -d "$src" ] || install -d -o ${user} -g ${cfg.group} "$src" || { failed=1; continue; }
          [ -d "$dst" ] || install -d -o ${user} -g ${cfg.group} "$dst" || { failed=1; continue; }
          mountpoint -q "$dst" || mount --bind "$src" "$dst" || failed=1
        done < ${directoriesFile}

        while IFS= read -r relative; do
          [ -n "$relative" ] || continue
          src="${persistentHome}/$relative"
          dst="${home}/$relative"
          ensure_parents ${persistentHome} "$relative"
          ensure_parents ${home} "$relative"
          [ -f "$src" ] || install -o ${user} -g ${cfg.group} -m 0600 /dev/null "$src" || { failed=1; continue; }
          [ -f "$dst" ] || install -o ${user} -g ${cfg.group} -m 0600 /dev/null "$dst" || { failed=1; continue; }
          mountpoint -q "$dst" || mount --bind "$src" "$dst" || failed=1
        done < ${filesFile}

        [ "$failed" = 0 ] || { echo "persist-user-binds: some binds failed" >&2; exit 1; }
        echo "persist-user-binds: allowlist mounted"
      ''}";
      log = true;
    };
  };
}
