{
  config,
  pkgs,
  disko,
  ...
}: let
  username = config.user.name or "y0usaf";
  homeDir = config.user.homeDirectory or "/home/${username}";
  disk = "/dev/sda";
in {
  imports = [
    disko.nixosModules.disko
  ];
  environment.systemPackages = [
    pkgs.disko
  ];
  disko.devices = {
    disk = {
      main = {
        device = disk;
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
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = ["compress=zstd" "noatime"];
                  };
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
    };
  };
}
