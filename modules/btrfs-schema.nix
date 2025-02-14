{
  config,
  lib,
  pkgs,
  ...
}: {
  options = {
    btrfsSchema = {
      enable = lib.mkEnableOption "BTRFS subvolume schema";
      rootDevice = lib.mkOption {
        type = lib.types.str;
        description = "UUID or label of the root BTRFS device";
      };
      mediaDevice = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "UUID or label of the media BTRFS device. If empty, rootDevice will be used.";
      };
      bootDevice = lib.mkOption {
        type = lib.types.str;
        description = "UUID or label of the boot device";
      };
      createSubvolumes = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to automatically create missing subvolumes during system activation";
      };
    };
  };

  config = lib.mkIf config.btrfsSchema.enable {
    fileSystems = {
      "/" = {
        device = "/dev/disk/by-uuid/${config.btrfsSchema.rootDevice}";
        fsType = "btrfs";
        options = ["subvol=@"];
      };

      "/home" = {
        device = "/dev/disk/by-uuid/${config.btrfsSchema.rootDevice}";
        fsType = "btrfs";
        options = ["subvol=@home"];
      };

      "/boot" = {
        device = "/dev/disk/by-uuid/${config.btrfsSchema.bootDevice}";
        fsType = "vfat";
        options = ["fmask=0077" "dmask=0077"];
      };

      "/home/y0usaf/Pictures" = {
        device = "/dev/disk/by-uuid/${if config.btrfsSchema.mediaDevice != "" then config.btrfsSchema.mediaDevice else config.btrfsSchema.rootDevice}";
        fsType = "btrfs";
        options = ["subvol=@pictures"];
      };

      "/home/y0usaf/DCIM" = {
        device = "/dev/disk/by-uuid/${if config.btrfsSchema.mediaDevice != "" then config.btrfsSchema.mediaDevice else config.btrfsSchema.rootDevice}";
        fsType = "btrfs";
        options = ["subvol=@dcim"];
      };

      "/home/y0usaf/Music" = {
        device = "/dev/disk/by-uuid/${if config.btrfsSchema.mediaDevice != "" then config.btrfsSchema.mediaDevice else config.btrfsSchema.rootDevice}";
        fsType = "btrfs";
        options = ["subvol=@music"];
      };

      "/home/y0usaf/.local/share/Steam" = {
        device = "/dev/disk/by-uuid/${if config.btrfsSchema.mediaDevice != "" then config.btrfsSchema.mediaDevice else config.btrfsSchema.rootDevice}";
        fsType = "btrfs";
        options = ["subvol=@steam"];
      };

      "/swap" = {
        device = "/dev/disk/by-uuid/${config.btrfsSchema.rootDevice}";
        fsType = "btrfs";
        options = ["subvol=@swap" "nodatacow"];
      };
    };

    systemd.services = lib.mkIf config.btrfsSchema.createSubvolumes {
      create-btrfs-subvolumes = {
        description = "Create BTRFS subvolumes if missing";
        wantedBy = ["local-fs-pre.target"];
        before = ["local-fs-pre.target"];
        path = [pkgs.btrfs-progs];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          StateDirectory = "btrfs-mounts";
        };
        script = let
          mediaDevice = if config.btrfsSchema.mediaDevice != "" 
                       then config.btrfsSchema.mediaDevice 
                       else config.btrfsSchema.rootDevice;
        in ''
          set -euo pipefail  # Fail on any error

          log_error() {
            echo "Error: $1" >&2
            systemd-notify --ready=0 --status="Failed: $1"
            exit 1
          }

          verify_device() {
            local device=$1
            if ! [ -e "$device" ]; then
              log_error "Device $device does not exist"
            fi
            if ! btrfs filesystem show "$device" &>/dev/null; then
              log_error "Device $device is not a BTRFS filesystem"
            fi
          }

          # Verify devices before starting
          verify_device "/dev/disk/by-uuid/${config.btrfsSchema.rootDevice}"
          verify_device "/dev/disk/by-uuid/${config.btrfsSchema.mediaDevice}"

          create_subvol() {
            local device=$1
            local subvol=$2
            local parent=$3
            local tmp_mount="/var/lib/btrfs-mounts/''${device##*/}"

            mkdir -p "$tmp_mount"

            if ! mountpoint -q "$tmp_mount"; then
              # Mount the root of the BTRFS filesystem
              mount -t btrfs -o subvolid=5 "$device" "$tmp_mount"

              if ! btrfs subvolume list "$tmp_mount" | grep -q "$subvol"; then
                if [ -n "$parent" ]; then
                  # If parent is specified, first mount the parent subvolume
                  local parent_mount="$tmp_mount/tmp_parent"
                  mkdir -p "$parent_mount"
                  mount -t btrfs -o "subvol=$parent" "$device" "$parent_mount"

                  # Create subvolume under the parent
                  btrfs subvolume create "$parent_mount/$subvol"

                  umount "$parent_mount"
                  rmdir "$parent_mount"
                else
                  # Create subvolume at root level
                  btrfs subvolume create "$tmp_mount/$subvol"
                fi
              fi

              umount "$tmp_mount"
            fi
          }

          # Create root-level subvolumes
          for subvol in @ @home @swap @log; do
            create_subvol "/dev/disk/by-uuid/${config.btrfsSchema.rootDevice}" "$subvol" ""
          done

          # Create nested subvolumes under @
          for subvol in "srv" "var/lib/portables" "var/lib/machines" "tmp" "var/tmp"; do
            create_subvol "/dev/disk/by-uuid/${config.btrfsSchema.rootDevice}" "$subvol" "@"
          done

          # Create media subvolumes at root level on the appropriate device
          for subvol in @pictures @dcim @music @steam; do
            create_subvol "/dev/disk/by-uuid/${mediaDevice}" "$subvol" ""
          done
        '';
      };

      verify-btrfs-schema = {
        description = "Verify BTRFS subvolume schema";
        after = ["create-btrfs-subvolumes.service"];
        script = ''
          verify_subvol_structure() {
            local device=$1
            local tmp_mount="/var/lib/btrfs-mounts/''${device##*/}"

            mount -t btrfs -o subvolid=5 "$device" "$tmp_mount"

            # Verify expected structure
            for subvol in @ @home @swap @log; do
              if ! btrfs subvolume list "$tmp_mount" | grep -q "$subvol"; then
                echo "Missing required subvolume: $subvol"
                exit 1
              fi
            done

            # Verify nested subvolumes
            if ! btrfs subvolume list "$tmp_mount" | grep -q "path @/var/tmp"; then
              echo "Missing required nested subvolume: @/var/tmp"
              exit 1
            fi

            umount "$tmp_mount"
          }
        '';
      };
    };

    assertions = [
      {
        assertion = config.btrfsSchema.enable -> config.btrfsSchema.rootDevice != "";
        message = "btrfsSchema.rootDevice must be set when btrfsSchema is enabled";
      }
      {
        assertion = config.btrfsSchema.enable -> config.btrfsSchema.bootDevice != "";
        message = "btrfsSchema.bootDevice must be set when btrfsSchema is enabled";
      }
    ];
  };
}
