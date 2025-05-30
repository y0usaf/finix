# Y0usaf-Laptop Disko Configuration - Fixed to match actual hardware
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

  # Define disk configuration to match your ACTUAL existing setup
  disko.devices = {
    disk = {
      # Main system disk - matches your actual partition layout
      system = {
        device = "/dev/nvme0n1";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              name = "boot";
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["fmask=0077" "dmask=0077"];
              };
            };
            root = {
              name = "root";
              size = "442.6G"; # Match your actual partition size
              content = {
                type = "btrfs";
                extraArgs = ["-f"];
                subvolumes = {
                  # Root subvolume - matches your actual setup
                  "@" = {
                    mountpoint = "/";
                    mountOptions = ["relatime" "ssd" "discard=async" "space_cache=v2" "subvol=@"];
                  };
                  # Home subvolume - matches your actual setup
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = ["relatime" "ssd" "discard=async" "space_cache=v2" "subvol=@home"];
                  };
                };
              };
            };
            swap = {
              name = "swap";
              size = "33.8G"; # Match your actual swap partition size
              content = {
                type = "swap";
              };
            };
          };
        };
      };
    };
  };

  # Use the existing swap partition - matches your hardware-configuration.nix
  swapDevices = [
    {device = "/dev/disk/by-uuid/be858002-6caa-4bca-8160-75cc21c1836e";}
  ];
}