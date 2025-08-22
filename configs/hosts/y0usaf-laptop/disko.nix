# Y0usaf-Laptop Disko Configuration - Fixed to match actual hardware
{
  pkgs,
  disko,
  ...
}: {
  imports = [
    disko.nixosModules.disko
  ];

  environment.systemPackages = [
    pkgs.disko
  ];

  disko.devices = {
    disk = {
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
              size = "442.6G";
              content = {
                type = "btrfs";
                extraArgs = ["-f"];
                subvolumes = {
                  "@" = {
                    mountpoint = "/";
                    mountOptions = ["relatime" "ssd" "discard=async" "space_cache=v2" "subvol=@"];
                  };
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = ["relatime" "ssd" "discard=async" "space_cache=v2" "subvol=@home"];
                  };
                };
              };
            };
            swap = {
              name = "swap";
              size = "33.8G";
              content = {
                type = "swap";
              };
            };
          };
        };
      };
    };
  };

  swapDevices = [
    {device = "/dev/disk/by-uuid/be858002-6caa-4bca-8160-75cc21c1836e";}
  ];
}
