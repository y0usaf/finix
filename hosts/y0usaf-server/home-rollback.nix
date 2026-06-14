_: {
  # Recreate @home from @home-blank on each boot (impermanence README pattern).
  # This keeps /home ephemeral without moving it to tmpfs.
  boot.initrd.systemd.services.home-rollback = {
    description = "Rollback @home btrfs subvolume to @home-blank snapshot";
    wantedBy = ["initrd.target"];
    after = ["dev-disk-by\\x2duuid-9dfc38c4\\x2d5c75\\x2d471d\\x2d9106\\x2d80ff9175ab92.device"];
    before = ["sysroot-home.mount"];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      mkdir -p /btrfs_tmp
      mount -t btrfs -o subvolid=5 /dev/disk/by-uuid/9dfc38c4-5c75-471d-9106-80ff9175ab92 /btrfs_tmp

      delete_subvolume_recursively() {
        IFS=$'\n'
        for subvolume in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
          delete_subvolume_recursively "/btrfs_tmp/$subvolume"
        done
        btrfs subvolume delete "$1" >/dev/null 2>&1 || true
      }

      # Seed a baseline snapshot on first boot after enabling this module.
      if [ ! -d /btrfs_tmp/@home-blank ]; then
        if [ -d /btrfs_tmp/@home ]; then
          btrfs subvolume snapshot -r /btrfs_tmp/@home /btrfs_tmp/@home-blank
        else
          btrfs subvolume create /btrfs_tmp/@home-blank
        fi
      fi

      if [ -d /btrfs_tmp/@home ]; then
        delete_subvolume_recursively /btrfs_tmp/@home
      fi

      btrfs subvolume snapshot /btrfs_tmp/@home-blank /btrfs_tmp/@home
      umount /btrfs_tmp
    '';
  };
}
