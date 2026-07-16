_: {
  # Recreate @home from @home-blank on each boot (impermanence README pattern).
  # Persistent user state lives in /persist (impermanence.nix, granular
  # allowlist); durable bulk data on dedicated subvols (@steam, @dcim,
  # @music, @pictures). Pre-P4 home read-only at ~/old-home (@home-old).
  # Pre-granular @config/@local snapshots: /btrfs/_premigration/.
  boot.initrd.systemd.services.home-rollback = {
    description = "Rollback @home btrfs subvolume to @home-blank snapshot";
    wantedBy = ["initrd.target"];
    after = ["dev-disk-by\\x2duuid-32ad19b5\\x2d88df\\x2d4e63\\x2d92d2\\x2dd5a150ad65c5.device"];
    before = ["sysroot-home.mount"];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      mkdir -p /btrfs_tmp
      mount -t btrfs -o subvolid=5 /dev/disk/by-uuid/32ad19b5-88df-4e63-92d2-d5a150ad65c5 /btrfs_tmp

      delete_subvolume_recursively() {
        IFS=$'\n'
        for subvolume in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
          delete_subvolume_recursively "/btrfs_tmp/$subvolume"
        done
        btrfs subvolume delete "$1" >/dev/null 2>&1 || true
      }

      # Blank baseline is pre-seeded (empty + y0usaf skeleton). If ever
      # missing, create an EMPTY one — never snapshot current @home.
      if [ ! -d /btrfs_tmp/@home-blank ]; then
        btrfs subvolume create /btrfs_tmp/@home-blank
      fi

      if [ -d /btrfs_tmp/@home ]; then
        # Keep previous boot's home for forgot-to-persist recovery
        # (inspect at /btrfs/@home-lastboot; rotated every boot).
        if [ -d /btrfs_tmp/@home-lastboot ]; then
          delete_subvolume_recursively /btrfs_tmp/@home-lastboot
        fi
        btrfs subvolume snapshot -r /btrfs_tmp/@home /btrfs_tmp/@home-lastboot
        delete_subvolume_recursively /btrfs_tmp/@home
      fi

      btrfs subvolume snapshot /btrfs_tmp/@home-blank /btrfs_tmp/@home
      umount /btrfs_tmp
    '';
  };
}
