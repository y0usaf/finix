{
  config,
  pkgs,
  disko,
  ...
}: let
  homeDir = config.system.homeDirectory or "/home/${config.system.username or "y0usaf"}";
in {
  imports = [
    disko.nixosModules.disko
  ];
  environment.systemPackages = [
    pkgs.disko
  ];
  disko.devices = {
    disk = {
      system = {
        device =
          {
            systemDisk = "/dev/nvme0n1";
          }.systemDisk;
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              name = "boot";
              size = "1G";
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
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = ["-f"];
                subvolumes = {
                  "@" = {
                    mountpoint = "/";
                    mountOptions = ["compress=zstd" "noatime"];
                  };
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = ["compress=zstd" "noatime"];
                  };
                  "@swap" = {
                    mountpoint = "/swap";
                    mountOptions = ["nodatacow" "noatime"];
                  };
                  "@config" = {
                    mountpoint = "${homeDir}/.config";
                    mountOptions = ["compress=zstd" "noatime"];
                  };
                  "@local" = {
                    mountpoint = "${homeDir}/.local";
                    mountOptions = ["compress=zstd" "noatime"];
                  };
                  "@steam" = {
                    mountpoint = "${homeDir}/.local/share/Steam";
                    mountOptions = ["compress=zstd" "noatime"];
                  };
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
                };
              };
            };
          };
        };
      };
    };
  };
  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 96768;
    }
  ];
}
