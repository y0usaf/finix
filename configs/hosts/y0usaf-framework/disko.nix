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
              size = "2G";
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
                    mountOptions = ["relatime" "ssd" "discard=async" "space_cache=v2" "subvol=@"];
                  };
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = ["relatime" "ssd" "discard=async" "space_cache=v2" "subvol=@home"];
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
