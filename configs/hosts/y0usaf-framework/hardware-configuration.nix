{
  config,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    initrd.availableKernelModules = ["nvme" "xhci_pci" "thunderbolt" "usbhid" "usb_storage" "sd_mod"];
    initrd.kernelModules = [];
    kernelModules = ["kvm-amd"];
    extraModulePackages = [];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/6ae685dc-540e-42f2-b30a-104a8aac0e27";
      fsType = "btrfs";
      options = ["subvol=@"];
    };

    "/home" = {
      device = "/dev/disk/by-uuid/6ae685dc-540e-42f2-b30a-104a8aac0e27";
      fsType = "btrfs";
      options = ["subvol=@home"];
    };

    "/nix" = {
      device = "/dev/disk/by-uuid/6ae685dc-540e-42f2-b30a-104a8aac0e27";
      fsType = "btrfs";
      options = ["subvol=@nix" "relatime" "ssd" "discard=async" "space_cache=v2"];
    };

    "/persist" = {
      device = "/dev/disk/by-uuid/6ae685dc-540e-42f2-b30a-104a8aac0e27";
      fsType = "btrfs";
      options = ["subvol=@persist" "relatime" "ssd" "discard=async" "space_cache=v2"];
      neededForBoot = true;
    };

    "/btrfs" = {
      device = "/dev/disk/by-uuid/6ae685dc-540e-42f2-b30a-104a8aac0e27";
      fsType = "btrfs";
      options = ["subvolid=5"];
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/6951-2BA6";
      fsType = "vfat";
      options = ["fmask=0077" "dmask=0077"];
    };
  };

  swapDevices = [];

  zramSwap = {
    enable = true;
    memoryPercent = 50;
    algorithm = "zstd";
    priority = 100;
  };

  boot.initrd.postDeviceCommands = lib.mkBefore ''
    mkdir /btrfs_tmp
    mount -o subvol=/ /dev/disk/by-uuid/6ae685dc-540e-42f2-b30a-104a8aac0e27 /btrfs_tmp

    delete_subvolume_recursively() {
      IFS=$'\n'
      for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
        delete_subvolume_recursively "/btrfs_tmp/$i"
      done
      btrfs subvolume delete "$1"
    }

    if [[ -e /btrfs_tmp/@ ]]; then
      delete_subvolume_recursively /btrfs_tmp/@
    fi

    btrfs subvolume create /btrfs_tmp/@
    umount /btrfs_tmp
  '';

  boot.tmp = {
    useTmpfs = true;
    tmpfsSize = "25%";
  };

  boot.kernel.sysctl."vm.swappiness" = 180;

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
