{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption types;
  dirPath = entry:
    if builtins.isAttrs entry
    then entry.directory
    else entry;
  directory = types.either types.str (types.submodule {
    options = {
      directory = mkOption {type = types.str;};
      mode = mkOption {
        type = types.str;
        default = "0755";
      };
    };
  });
  paths = {
    directories = mkOption {
      type = types.listOf directory;
      default = [];
    };
    files = mkOption {
      type = types.listOf types.str;
      default = [];
    };
  };
in {
  options.finix.persistence = {
    allowlist = mkOption {
      description = "Host persistence policy consumed by native Finix mount modules.";
      default = {};
      type = types.submodule {
        options =
          paths
          // {
            hideMounts = mkOption {
              type = types.bool;
              default = true;
            };
            users = mkOption {
              type = types.attrsOf (types.submodule {options = paths;});
              default = {};
            };
          };
      };
    };
  };

  config = let
    user = config.user.name;
    userPersist = config.finix.persistence.allowlist.users.${user};
    home = config.user.homeDirectory;
    persistentHome = "/persist/home/${user}";
    sorted = paths: lib.sort lib.lessThan (lib.unique paths);
    directoriesFile = pkgs.writeText "persist-user-directories" (lib.concatMapStrings (path: "${path}
") (sorted (map dirPath userPersist.directories)));
    filesFile = pkgs.writeText "persist-user-files" (lib.concatMapStrings (path: "${path}
") (sorted (map dirPath userPersist.files)));
  in {
    environment.systemPackages = let
      inherit (config.users.users.${user}) uid;
      splitPath = p: builtins.filter (s: s != "") (lib.splitString "/" p);
      properAncestors = p: let
        parts = splitPath p;
      in
        lib.init (lib.genList (i: lib.concatStringsSep "/" (lib.take (i + 1) parts)) (lib.length parts));
      dirnameOf = p: let
        parts = splitPath p;
      in
        lib.optional (lib.length parts > 1) (lib.concatStringsSep "/" (lib.init parts));
      fileTemplateDirs = builtins.concatMap (f: let
        d = dirnameOf (dirPath f);
      in
        d ++ lib.concatMap properAncestors d)
      userPersist.files;
      dirTemplateDirs = builtins.concatMap (d: properAncestors (dirPath d)) userPersist.directories;
      dataSubvolMounts =
        map (mp: lib.removePrefix "${home}/" mp)
        (builtins.filter (mp: lib.hasPrefix "${home}/" mp) (builtins.attrNames config.fileSystems));
      templateDirs = lib.sort lib.lessThan (lib.unique (dataSubvolMounts ++ dirTemplateDirs ++ fileTemplateDirs));
    in [
      (pkgs.writeShellScriptBin "prep-home-blank" ''
        set -euo pipefail

        export PATH=${lib.makeBinPath [pkgs.btrfs-progs pkgs.coreutils pkgs.util-linux]}

        mountpoint -q /btrfs || {
          echo "prep-home-blank: /btrfs is not a mountpoint" >&2
          exit 1
        }

        if btrfs subvolume show /btrfs/@home-blank >/dev/null 2>&1; then
          if [ "''${1:-}" != "--force" ]; then
            echo "prep-home-blank: /btrfs/@home-blank already exists; rerun with --force to delete and recreate" >&2
            exit 1
          fi
          echo "prep-home-blank: --force: deleting existing /btrfs/@home-blank"
          btrfs subvolume delete /btrfs/@home-blank
        fi

        btrfs subvolume create /btrfs/@home-blank

        install -d -m 0700 -o ${toString uid} -g users /btrfs/@home-blank/${user}
        while IFS= read -r dir; do
          [ -n "$dir" ] || continue
          install -d -m 0755 -o ${toString uid} -g users "/btrfs/@home-blank/${user}/$dir"
        done <<'DIRS'
        ${lib.concatStringsSep "\n" templateDirs}
        DIRS

        chown -R ${toString uid}:users /btrfs/@home-blank/${user}
        echo "prep-home-blank: @home-blank ready ($((1 + ${toString (builtins.length templateDirs)})) dirs)"
      '')
    ];

    boot.initrd.finit.tasks = {
      reset-home = {
        description = "rotate home back to the blank Btrfs template";
        conditions = ["task/mount-btrfs/success"];
        script = ''
          B=/sysroot/btrfs
          live="$B/@home"
          fresh="$B/@home-new"
          previous="$B/@home-lastboot"
          template="$B/@home-blank"

          if ! btrfs subvolume show "$live" >/dev/null 2>&1; then
            if btrfs subvolume show "$fresh" >/dev/null 2>&1; then
              mv "$fresh" "$live" || { echo "reset-home: FATAL: promote fresh home failed" >&2; exit 1; }
            elif btrfs subvolume show "$previous" >/dev/null 2>&1; then
              mv "$previous" "$live" || { echo "reset-home: FATAL: restore previous home failed" >&2; exit 1; }
            else
              echo "reset-home: FATAL: no recoverable home subvolume" >&2
              exit 1
            fi
            exit 0
          fi

          if btrfs subvolume show "$fresh" >/dev/null 2>&1; then
            btrfs subvolume delete "$fresh" || { echo "reset-home: skip: stale fresh snapshot could not be deleted"; exit 0; }
          fi
          if ! btrfs subvolume show "$template" >/dev/null 2>&1; then
            echo "reset-home: skip: no template"
            exit 0
          fi
          btrfs subvolume snapshot "$template" "$fresh" || { echo "reset-home: skip: snapshot failed"; exit 0; }
          if btrfs subvolume show "$previous" >/dev/null 2>&1; then
            btrfs subvolume delete "$previous" || {
              btrfs subvolume delete "$fresh" || true
              echo "reset-home: skip: previous snapshot could not be deleted"
              exit 0
            }
          fi
          mv "$live" "$previous" || {
            btrfs subvolume delete "$fresh" || true
            echo "reset-home: skip: live rotation failed"
            exit 0
          }
          mv "$fresh" "$live" || {
            mv "$previous" "$live" || true
            echo "reset-home: skip: promotion failed; rolled back"
            exit 0
          }
          echo "reset-home: success"
        '';
      };
      "mount-home".conditions = ["task/reset-home/success"];
    };

    system.activation.scripts.persistentMachineId.text = ''
      if [ -s /persist/etc/machine-id ]; then
        ${pkgs.coreutils}/bin/install -m 0444 /persist/etc/machine-id /etc/machine-id
      fi
    '';

    fileSystems = lib.genAttrs (builtins.filter (dir: !lib.hasPrefix "/etc/" dir && dir != "/root")
      (map dirPath config.finix.persistence.allowlist.directories)) (dir: {
      device = "/persist${dir}";
      fsType = "btrfs";
      options = ["bind"];
      neededForBoot = true;
    });

    finit.tasks.persist-user-binds = {
      description = "replay the user persistence allowlist as bind mounts";
      command = "${pkgs.writeShellScript "persist-user-binds" ''
        set -u
        export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.util-linux]}

        for _ in $(seq 1 120); do
          mountpoint -q /persist && mountpoint -q /home && break
          sleep 1
        done
        mountpoint -q /persist || { echo "persist-user-binds: /persist never mounted" >&2; exit 1; }
        mountpoint -q /home || { echo "persist-user-binds: /home never mounted" >&2; exit 1; }

        install -d -m 0700 -o ${user} -g users ${home}
        install -d -m 0755 ${persistentHome}
        chown ${user}:users ${home} || true

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
              chown ${user}:users "$directory" || true
            else
              install -d -m 0755 -o ${user} -g users "$directory" || true
            fi
          done
        }

        failed=0
        ${lib.optionalString (builtins.elem "/root" (map dirPath config.finix.persistence.allowlist.directories)) ''
          install -d -m 0700 /persist/root
          install -d -m 0700 /root
          mountpoint -q /root || mount --bind /persist/root /root || failed=1
        ''}

        while IFS= read -r relative; do
          [ -n "$relative" ] || continue
          src="${persistentHome}/$relative"
          dst="${home}/$relative"
          ensure_parents ${persistentHome} "$relative"
          ensure_parents ${home} "$relative"
          [ -d "$src" ] || install -d -o ${user} -g users "$src" || { failed=1; continue; }
          [ -d "$dst" ] || install -d -o ${user} -g users "$dst" || { failed=1; continue; }
          mountpoint -q "$dst" || mount --bind "$src" "$dst" || failed=1
        done < ${directoriesFile}

        while IFS= read -r relative; do
          [ -n "$relative" ] || continue
          src="${persistentHome}/$relative"
          dst="${home}/$relative"
          ensure_parents ${persistentHome} "$relative"
          ensure_parents ${home} "$relative"
          [ -f "$src" ] || install -o ${user} -g users -m 0600 /dev/null "$src" || { failed=1; continue; }
          [ -f "$dst" ] || install -o ${user} -g users -m 0600 /dev/null "$dst" || { failed=1; continue; }
          mountpoint -q "$dst" || mount --bind "$src" "$dst" || failed=1
        done < ${filesFile}

        [ "$failed" = 0 ] || { echo "persist-user-binds: some binds failed" >&2; exit 1; }
        echo "persist-user-binds: allowlist mounted"
      ''}";
      log = true;
    };

    finix.persistence = {
      allowlist = {
        hideMounts = true;
        directories = [
          "/etc/NetworkManager/system-connections"
          "/etc/ssh"
          "/var/lib/NetworkManager"
          "/var/lib/bluetooth"
          "/var/lib/manzil"
          "/var/lib/nixos"
          "/var/lib/systemd/coredump"
          "/var/lib/tailscale"
          "/var/log"
        ];
        files = ["/etc/machine-id"];
        users.${config.user.name} = {
          directories = [
            ".azure"
            ".cache/mesa_shader_cache"
            ".cache/nix"
            ".cache/nv"
            ".config/AionUi"
            ".config/Frame"
            ".config/GitHub Desktop"
            ".config/Hermes"
            ".config/Mullvad VPN"
            ".config/age"
            ".config/agent-harness"
            ".config/camset"
            ".config/claude"
            ".config/dconf"
            ".config/epy"
            ".config/firefox"
            ".config/herdr"
            ".config/intent"
            ".config/manicode"
            ".config/nix"
            ".config/nushell"
            ".config/slskd"
            ".config/snowflake"
            ".cookunity"
            ".cursor/sand"
            ".cursor/sand-dev"
            ".hermes"
            ".local/share/Vial"
            ".local/share/app.codeg"
            ".local/share/applications"
            ".local/share/azure"
            ".local/share/com.jean.desktop"
            ".local/share/com.pais.handy"
            ".local/share/com.panes.app"
            ".local/share/gnupg"
            ".local/share/handy"
            ".local/share/icons"
            ".local/share/keyrings"
            ".local/share/mcp-trader"
            ".local/share/music-get"
            ".local/share/pki"
            ".local/share/polybot"
            ".local/share/slskd"
            ".local/share/superfile"
            ".local/share/vibe-kanban"
            ".local/state/bash"
            ".local/state/manzil"
            ".local/state/music-get"
            ".local/state/nix"
            ".local/state/superfile"
            ".mcp-auth"
            ".mozilla"
            ".n8n-mcp"
            ".paseo"
            ".pki"
            ".slskd"
            ".supabase"
            "Desktop"
            "Documents"
            "Downloads"
            "Games"
            "Tokens"
            "Videos"
            "cu-workbench"
            "finix"
            "inscend"
          ];
          files = [".SNOW"];
        };
      };
    };
  };
}
