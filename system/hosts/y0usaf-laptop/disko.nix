# Y0usaf-Laptop Disko Configuration
{
  lib,
  config,
  pkgs,
  disko,
  ...
}: let
  username = config.cfg.system.username or "y0usaf";
  homeDir = config.cfg.system.homeDirectory or "/home/${username}";

  # Configurable options - single disk for laptop
  disks = {
    systemDisk = "/dev/nvme0n1"; # Update this based on actual laptop hardware
  };

  # Swap size for laptop (adjust based on RAM size)
  swapSize = 16384; # 16GB - adjust based on your laptop's RAM
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
      # Main system disk (only disk on laptop)
      system = {
        device = disks.systemDisk;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              name = "boot";
              size = "512M";
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
                  # Media directories - all on system disk for laptop
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
                  # Steam directory - on system disk for laptop
                  "@steam" = {
                    mountpoint = "${homeDir}/.local/share/Steam";
                    mountOptions = ["compress=zstd" "noatime"];
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  # Swap file configuration
  swapDevices = [
    {
      device = "/swap/swapfile";
      size = swapSize;
    }
  ];
}
