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
    # Define essential mounts
    fileSystems = lib.mkMerge [
      {
        "/" = {
          device = "/dev/disk/by-uuid/${config.btrfsSchema.rootDevice}";
          fsType = "btrfs";
          options = ["subvol=@"];
        };

        "/boot" = {
          device = "/dev/disk/by-uuid/${config.btrfsSchema.bootDevice}";
          fsType = "vfat";
          options = ["fmask=0077" "dmask=0077"];
        };
      }
      # Additional mounts that refer to subvolumes you expect the creation service to (re)create:
      (lib.mkIf config.btrfsSchema.createSubvolumes {
        "/home" = {
          device = "/dev/disk/by-uuid/${config.btrfsSchema.rootDevice}";
          fsType = "btrfs";
          options = ["subvol=@home"];
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
      })
    ];

    # Define services which create and then verify the subvolume layout.
    systemd.services = lib.mkIf config.btrfsSchema.createSubvolumes {
      create-btrfs-subvolumes = {
        description = "Create missing BTRFS subvolumes if absent";
        # Running after local-fs.target means that we try to fix things later,
        # and a failure here won't necessarily force emergency mode.
        wantedBy = ["multi-user.target"];
        after = ["local-fs.target"];
        path = [pkgs.btrfs-progs];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          StandardOutput = "journal";
          StandardError = "journal";
          # A no-op ExecStartPre; you can adjust further as needed.
          ExecStartPre = "${pkgs.coreutils}/bin/true";
        };
        script = let
          mountBase = "/var/lib/btrfs-mounts";
          rootDevicePath = "/dev/disk/by-uuid/${config.btrfsSchema.rootDevice}";
          mediaDevicePath =
            if config.btrfsSchema.mediaDevice != "" then
              "/dev/disk/by-uuid/${config.btrfsSchema.mediaDevice}"
            else
              rootDevicePath;
        in ''
          #!/usr/bin/env bash
          set -euo pipefail

          mkdir -p "${mountBase}"

          log() {
            echo "[create-btrfs-subvolumes] $1"
          }

          create_subvol() {
            local device="$1"
            local subvol="$2"
            local parent="$3"
            local devIdentifier
            devIdentifier=$(basename "$device")
            local mountDir="${mountBase}/${devIdentifier}"
            mkdir -p "$mountDir" || { log "Failed to create mount dir $mountDir"; return 1; }
            if ! mountpoint -q "$mountDir"; then
              if ! mount -t btrfs -o subvolid=5 "$device" "$mountDir"; then
                log "Warning: Failed to mount $device on $mountDir, skipping subvolume $subvol"
                return 1
              fi
            fi

            if ! btrfs subvolume list "$mountDir" | grep -qw "$subvol"; then
              log "Creating subvolume $subvol on device $device"
              if [ -n "$parent" ]; then
                local parent_mount="${mountDir}/parent_mount"
                mkdir -p "$parent_mount" ||
                  { log "Failed to create temporary mount $parent_mount"; umount "$mountDir"; return 1; }
                if mount -t btrfs -o "subvol=${parent}" "$device" "$parent_mount"; then
                  if ! btrfs subvolume create "$parent_mount/$subvol"; then
                    log "Warning: Failed to create subvolume $subvol under parent $parent on device $device"
                  fi
                  umount "$parent_mount"
                  rmdir "$parent_mount"
                else
                  log "Warning: Failed to mount parent subvolume $parent on device $device"
                fi
              else
                if ! btrfs subvolume create "$mountDir/$subvol"; then
                  log "Warning: Failed to create subvolume $subvol on device $device"
                fi
              fi
            else
              log "Subvolume $subvol already exists on device $device"
            fi
            umount "$mountDir" || true
          }

          # Create essential subvolumes on the root device.
          for subvol in "@" "@home" "@swap" "@log"; do
            create_subvol "${rootDevicePath}" "$subvol" ""
          done

          # Create nested subvolumes under "@".
          for subvol in "srv" "var/lib/portables" "var/lib/machines" "tmp" "var/tmp"; do
            create_subvol "${rootDevicePath}" "$subvol" "@"
          done

          # Create media subvolumes on the media device.
          for subvol in "@pictures" "@dcim" "@music" "@steam"; do
            create_subvol "${mediaDevicePath}" "$subvol" ""
          done

          log "BTRFS subvolume creation process completed."
        '';
      };

      verify-btrfs-schema = {
        description = "Verify BTRFS subvolume schema (warning only, non-fatal)";
        after = ["create-btrfs-subvolumes.service"];
        serviceConfig = {
          Type = "oneshot";
          StandardOutput = "journal";
          StandardError = "journal";
          ExecStartPre = "${pkgs.coreutils}/bin/true";
        };
        script = let
          mountPoint = "/var/lib/btrfs-mounts/verify";
          rootDevicePath = "/dev/disk/by-uuid/${config.btrfsSchema.rootDevice}";
        in ''
          #!/usr/bin/env bash
          set -euo pipefail
          mkdir -p "${mountPoint}"
          if ! mount -t btrfs -o subvolid=5 "${rootDevicePath}" "${mountPoint}"; then
            echo "[verify-btrfs-schema] Warning: Failed to mount ${rootDevicePath} for verification."
            exit 0
          fi

          missing=""
          for subvol in "@" "@home" "@swap" "@log"; do
            if ! btrfs subvolume list "${mountPoint}" | grep -qw "${subvol}"; then
              missing="${missing} ${subvol}"
            fi
          done

          if [ -n "${missing}" ]; then
            echo "[verify-btrfs-schema] Warning: Missing essential subvolumes:${missing}"
          else
            echo "[verify-btrfs-schema] BTRFS subvolume schema verified successfully."
          fi

          umount "${mountPoint}" || true
          rmdir "${mountPoint}" || true
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
