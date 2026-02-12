{
  config,
  lib,
  ...
}: {
  options.services.btrbk-snapshots = {
    enable = lib.mkEnableOption "btrbk btrfs snapshot management";

    subvolumes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["@dcim" "@music"];
      description = "List of btrfs subvolume names to snapshot";
    };
  };

  config = lib.mkIf config.services.btrbk-snapshots.enable {
    services.btrbk.instances.snapshots = {
      onCalendar = "daily";
      settings = {
        timestamp_format = "long";
        snapshot_preserve_min = "2d";
        snapshot_preserve = "7d 4w";

        volume."/btrfs" = {
          snapshot_dir = "_snapshots";
          subvolume = lib.genAttrs config.services.btrbk-snapshots.subvolumes (_: {});
        };
      };
    };
  };
}
