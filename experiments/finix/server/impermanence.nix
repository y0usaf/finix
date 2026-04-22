{
  device,
  includeMediaSubvols ? true,
}: {
  config,
  lib,
  pkgs,
  ...
}: {
  boot.kernelModules = ["btrfs"];

  environment.systemPackages = [pkgs.btrfs-progs];

  system.activation.path = lib.mkAfter [pkgs.btrfs-progs];

  # Finix impermanence: rebuild /home from @home-blank each boot, keep /persist
  # across reboots. Parameterized so the same logic is reused for:
  #   - server-vm  (device = /dev/vdb, mkfs if empty)
  #   - bare metal (device = /dev/disk/by-uuid/<shared fs>, never mkfs)
  system.activation.scripts.finixImpermanence = {
    deps = ["etc" "users"];
    text = ''
      set -eu

      device=${device}
      btrfs_top=/btrfs
      persist_root=/persist

      for _ in $(seq 1 30); do
        if [ -b "$device" ]; then
          break
        fi
        sleep 1
      done

      if ! [ -b "$device" ]; then
        echo "finix-impermanence: missing $device"
        exit 1
      fi

      fs_type="$(${pkgs.util-linux}/bin/blkid -o value -s TYPE "$device" 2>/dev/null || true)"
      if [ -z "$fs_type" ]; then
        echo "finix-impermanence: formatting $device as btrfs"
        ${pkgs.btrfs-progs}/bin/mkfs.btrfs -f -L finix-persist "$device" >/dev/null
      elif [ "$fs_type" != "btrfs" ]; then
        echo "finix-impermanence: refusing to overwrite non-btrfs filesystem on $device ($fs_type)"
        exit 1
      fi

      mkdir -p "$btrfs_top"
      if ! mountpoint -q "$btrfs_top"; then
        mount -t btrfs -o subvolid=5 "$device" "$btrfs_top"
      fi

      ensure_subvolume() {
        local path="$1"
        if ! [ -d "$path" ]; then
          ${pkgs.btrfs-progs}/bin/btrfs subvolume create "$path" >/dev/null
        fi
      }

      delete_subvolume_recursively() {
        local path="$1"
        local subvolume

        if ! [ -d "$path" ]; then
          return 0
        fi

        while IFS= read -r subvolume; do
          delete_subvolume_recursively "$btrfs_top/$subvolume"
        done < <(${pkgs.btrfs-progs}/bin/btrfs subvolume list -o "$path" | cut -f 9- -d ' ')

        ${pkgs.btrfs-progs}/bin/btrfs subvolume delete "$path" >/dev/null 2>&1 || true
      }

      ensure_subvolume "$btrfs_top/@persist"
      ensure_subvolume "$btrfs_top/@home"
      ${lib.optionalString includeMediaSubvols ''
        ensure_subvolume "$btrfs_top/@music"
        ensure_subvolume "$btrfs_top/@dcim"
        ensure_subvolume "$btrfs_top/@pictures"
      ''}

      if ! [ -d "$btrfs_top/@home-blank" ]; then
        ${pkgs.btrfs-progs}/bin/btrfs subvolume snapshot -r "$btrfs_top/@home" "$btrfs_top/@home-blank" >/dev/null
      fi

      delete_subvolume_recursively "$btrfs_top/@home"
      ${pkgs.btrfs-progs}/bin/btrfs subvolume snapshot "$btrfs_top/@home-blank" "$btrfs_top/@home" >/dev/null

      mkdir -p "$persist_root" /home /home/y0usaf
      ${lib.optionalString includeMediaSubvols ''
        mkdir -p /home/y0usaf/Music /home/y0usaf/DCIM /home/y0usaf/Pictures
      ''}

      if ! mountpoint -q "$persist_root"; then
        mount -t btrfs -o subvol=@persist,compress=zstd,noatime "$device" "$persist_root"
      fi

      if ! mountpoint -q /home; then
        mount -t btrfs -o subvol=@home,compress=zstd,noatime "$device" /home
      fi

      mkdir -p /home/y0usaf

      ${lib.optionalString includeMediaSubvols ''
        mkdir -p /home/y0usaf/Music /home/y0usaf/DCIM /home/y0usaf/Pictures

        if ! mountpoint -q /home/y0usaf/Music; then
          mount -t btrfs -o subvol=@music,compress=zstd,noatime "$device" /home/y0usaf/Music
        fi

        if ! mountpoint -q /home/y0usaf/DCIM; then
          mount -t btrfs -o subvol=@dcim,compress=zstd,noatime "$device" /home/y0usaf/DCIM
        fi

        if ! mountpoint -q /home/y0usaf/Pictures; then
          mount -t btrfs -o subvol=@pictures,compress=zstd,noatime "$device" /home/y0usaf/Pictures
        fi
      ''}

      ${pkgs.coreutils}/bin/install -d -m 0755 "$persist_root/etc"
      ${pkgs.coreutils}/bin/install -d -m 0755 "$persist_root/var/log"
      ${pkgs.coreutils}/bin/install -d -m 0755 "$persist_root/var/lib/sshd"
      ${pkgs.coreutils}/bin/install -d -m 0755 "$persist_root/var/lib/postgresql"
      ${pkgs.coreutils}/bin/install -d -m 0750 "$persist_root/var/lib/forgejo"
      ${pkgs.coreutils}/bin/install -d -m 0755 "$persist_root/var/lib/docker"
      ${pkgs.coreutils}/bin/install -d -m 0755 "$persist_root/var/lib/tailscale"
      ${pkgs.coreutils}/bin/install -d -m 0750 "$persist_root/var/lib/n8n"
      ${pkgs.coreutils}/bin/install -d -m 0750 "$persist_root/var/lib/mediamtx"
      ${pkgs.coreutils}/bin/install -d -m 0750 "$persist_root/var/lib/bayt"
      ${pkgs.coreutils}/bin/install -d -m 0750 "$persist_root/var/lib/btrbk"
      ${pkgs.coreutils}/bin/install -d -m 0750 "$persist_root/var/lib/blocky"
      ${pkgs.coreutils}/bin/install -d -m 0750 "$persist_root/var/lib/acme"
      ${pkgs.coreutils}/bin/install -d -m 0755 "$persist_root/secrets"
      ${pkgs.coreutils}/bin/install -d -m 0700 "$persist_root/secrets/password-hashes"
      ${pkgs.coreutils}/bin/install -d -m 0700 "$persist_root/home/y0usaf"
      ${pkgs.coreutils}/bin/install -d -m 0700 "$persist_root/home/y0usaf/.hermes"
      ${pkgs.coreutils}/bin/install -d -m 0700 "$persist_root/home/y0usaf/.codex"
      ${pkgs.coreutils}/bin/install -d -m 0700 "$persist_root/home/y0usaf/.claude"
      ${pkgs.coreutils}/bin/install -d -m 0700 "$persist_root/home/y0usaf/.config/claude"
      ${pkgs.coreutils}/bin/install -d -m 0700 "$persist_root/home/y0usaf/.config/syncthing"
      ${pkgs.coreutils}/bin/install -d -m 0700 "$persist_root/home/y0usaf/.local/state/syncthing"
      ${pkgs.coreutils}/bin/install -d -m 0755 "$persist_root/home/y0usaf/nixos"

      ${pkgs.coreutils}/bin/chown -R postgres:postgres "$persist_root/var/lib/postgresql"
      ${pkgs.coreutils}/bin/chown -R forgejo:forgejo "$persist_root/var/lib/forgejo"
      ${pkgs.coreutils}/bin/chown -R n8n:n8n "$persist_root/var/lib/n8n"
      ${pkgs.coreutils}/bin/chown -R mediamtx:mediamtx "$persist_root/var/lib/mediamtx"
      ${pkgs.coreutils}/bin/chown -R y0usaf:users "$persist_root/home/y0usaf"

      persist_link_dir() {
        local target="$1"
        local source="$2"

        mkdir -p "$(dirname "$target")"
        mkdir -p "$(dirname "$source")"

        if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
          return 0
        fi

        rm -rf "$target"
        ln -sfn "$source" "$target"
      }

      if ! [ -s "$persist_root/etc/machine-id" ]; then
        ${pkgs.coreutils}/bin/cat /proc/sys/kernel/random/uuid | ${pkgs.coreutils}/bin/tr -d '-' > "$persist_root/etc/machine-id"
      fi

      rm -f /etc/machine-id
      ln -sfn "$persist_root/etc/machine-id" /etc/machine-id

      persist_link_dir /var/log "$persist_root/var/log"
      persist_link_dir /var/lib/sshd "$persist_root/var/lib/sshd"
      persist_link_dir /var/lib/postgresql "$persist_root/var/lib/postgresql"
      persist_link_dir /var/lib/forgejo "$persist_root/var/lib/forgejo"
      persist_link_dir /var/lib/docker "$persist_root/var/lib/docker"
      persist_link_dir /var/lib/tailscale "$persist_root/var/lib/tailscale"
      persist_link_dir /var/lib/n8n "$persist_root/var/lib/n8n"
      persist_link_dir /var/lib/mediamtx "$persist_root/var/lib/mediamtx"
      persist_link_dir /var/lib/bayt "$persist_root/var/lib/bayt"
      persist_link_dir /var/lib/btrbk "$persist_root/var/lib/btrbk"
      persist_link_dir /var/lib/blocky "$persist_root/var/lib/blocky"
      persist_link_dir /var/lib/acme "$persist_root/var/lib/acme"
      persist_link_dir /home/y0usaf/.hermes "$persist_root/home/y0usaf/.hermes"
      persist_link_dir /home/y0usaf/.codex "$persist_root/home/y0usaf/.codex"
      persist_link_dir /home/y0usaf/.claude "$persist_root/home/y0usaf/.claude"
      persist_link_dir /home/y0usaf/.config/claude "$persist_root/home/y0usaf/.config/claude"
      persist_link_dir /home/y0usaf/.config/syncthing "$persist_root/home/y0usaf/.config/syncthing"
      persist_link_dir /home/y0usaf/.local/state/syncthing "$persist_root/home/y0usaf/.local/state/syncthing"
      persist_link_dir /home/y0usaf/nixos "$persist_root/home/y0usaf/nixos"

      if ! [ -e "$persist_root/home/y0usaf/.claude.json" ]; then
        : > "$persist_root/home/y0usaf/.claude.json"
        ${pkgs.coreutils}/bin/chown y0usaf:users "$persist_root/home/y0usaf/.claude.json"
      fi

      rm -f /home/y0usaf/.claude.json
      ln -sfn "$persist_root/home/y0usaf/.claude.json" /home/y0usaf/.claude.json
    '';
  };
}
