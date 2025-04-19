# Y0usaf-Desktop Disko Configuration
{
  lib,
  config,
  pkgs,
  disko,
  ...
}: let
  username = config.cfg.system.username or "y0usaf";
  homeDir = config.cfg.system.homeDirectory or "/home/${username}";

  # Configurable options
  disks = {
    systemDisk = "/dev/nvme0n1";
    dataDisk = "/dev/nvme1n1";
  };
in {
  imports = [
    disko.nixosModules.disko
  ];

  # Add disko to the system packages
  environment.systemPackages = [
    pkgs.disko
  ];

  # Define disk configuration
  disko.devices = {
    disk = {
      # Main system disk
      system = {
        device = disks.systemDisk;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              name = "boot";
              size = "1G";
              type = "EF00"; # EFI System Partition
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["fmask=0077" "dmask=0077"];
              };
            };
            root = {
              name = "root";
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = ["-f"]; # Force formatting
                subvolumes = {
                  # Root filesystem
                  "@" = {
                    mountpoint = "/";
                    mountOptions = ["compress=zstd" "noatime"];
                  };
                  # Home directory
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = ["compress=zstd" "noatime"];
                  };
                  # Swap directory
                  "@swap" = {
                    mountpoint = "/swap";
                    mountOptions = ["nodatacow" "noatime"];
                  };
                };
              };
            };
          };
        };
      };

      # Secondary data disk
      data = {
        device = disks.dataDisk;
        type = "disk";
        content = {
          type = "btrfs";
          extraArgs = ["-f"]; # Force formatting
          subvolumes = {
            # Media subvolumes
            "@pictures" = {
              mountpoint = "${homeDir}/Pictures";
              mountOptions = ["compress=zstd" "noatime"];
            };
            "@dcim" = {
              mountpoint = "${homeDir}/DCIM";
              mountOptions = ["compress=zstd" "noatime"];
            };
            "@music" = {
              mountpoint = "${homeDir}/Music";
              mountOptions = ["compress=zstd" "noatime"];
            };
            # Steam directory
            "@steam" = {
              mountpoint = "${homeDir}/.local/share/Steam";
              mountOptions = ["compress=zstd" "noatime"];
            };
          };
        };
      };
    };
  };

  # Swap file configuration - could be moved to the host's default.nix if preferred
  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 96768; # 96GB + 768MB for hibernation
    }
  ];
}
