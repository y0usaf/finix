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
    initrd.availableKernelModules = [
      "nvme"
      "thunderbolt"
      "xhci_pci"
      "ahci"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];
    initrd.kernelModules = [];
    kernelModules = [
      "kvm-amd"
      "k10temp"
      "nct6775"
      "zenpower"
    ];
    extraModulePackages = [config.boot.kernelPackages.zenpower];
    kernelParams = [
      "amd_pstate=active"
      "mitigations=off"
    ];
  };
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/32ad19b5-88df-4e63-92d2-d5a150ad65c5";
      fsType = "btrfs";
      options = [
        "subvol=@"
        "compress=zstd:3"
        "noatime"
        "ssd"
        "space_cache=v2"
      ];
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/31F2-1AE7";
      fsType = "vfat";
      options = ["fmask=0077" "dmask=0077"];
    };
    "/btrfs" = {
      device = "/dev/disk/by-uuid/32ad19b5-88df-4e63-92d2-d5a150ad65c5";
      fsType = "btrfs";
      options = [
        "subvolid=5"
        "compress=zstd:3"
        "noatime"
        "ssd"
        "space_cache=v2"
      ];
    };
    "/btrfs/data" = {
      device = "/dev/disk/by-uuid/9df24ce7-8abe-4a4b-9c9d-1a5c1c894051";
      fsType = "btrfs";
      options = [
        "subvolid=5"
        "compress=zstd:3"
        "noatime"
        "ssd"
        "space_cache=v2"
      ];
    };
    "/home" = {
      device = "/dev/disk/by-uuid/32ad19b5-88df-4e63-92d2-d5a150ad65c5";
      fsType = "btrfs";
      options = [
        "subvol=@home"
        "compress=zstd:3"
        "noatime"
        "ssd"
        "space_cache=v2"
      ];
    };
    "/swap" = {
      device = "/dev/disk/by-uuid/32ad19b5-88df-4e63-92d2-d5a150ad65c5";
      fsType = "btrfs";
      options = [
        "subvol=@swap"
        "nodatacow"
        "compress=no"
        "noatime"
        "ssd"
        "space_cache=v2"
      ];
    };
    "/home/y0usaf/.config" = {
      device = "/dev/disk/by-uuid/32ad19b5-88df-4e63-92d2-d5a150ad65c5";
      fsType = "btrfs";
      options = [
        "subvol=@config"
        "compress=zstd:3"
        "noatime"
        "ssd"
        "space_cache=v2"
      ];
    };
    "/home/y0usaf/.local" = {
      device = "/dev/disk/by-uuid/32ad19b5-88df-4e63-92d2-d5a150ad65c5";
      fsType = "btrfs";
      options = [
        "subvol=@local"
        "compress=zstd:3"
        "noatime"
        "ssd"
        "space_cache=v2"
      ];
    };
    "/home/y0usaf/.local/share/Steam" = {
      device = "/dev/disk/by-uuid/9df24ce7-8abe-4a4b-9c9d-1a5c1c894051";
      fsType = "btrfs";
      options = [
        "subvol=@steam"
        "compress=zstd:3"
        "noatime"
        "ssd"
        "space_cache=v2"
      ];
    };
    "/home/y0usaf/Pictures" = {
      device = "/dev/disk/by-uuid/9df24ce7-8abe-4a4b-9c9d-1a5c1c894051";
      fsType = "btrfs";
      options = [
        "subvol=@pictures"
        "compress=zstd:3"
        "noatime"
        "ssd"
        "space_cache=v2"
      ];
    };
    "/home/y0usaf/DCIM" = {
      device = "/dev/disk/by-uuid/9df24ce7-8abe-4a4b-9c9d-1a5c1c894051";
      fsType = "btrfs";
      options = [
        "subvol=@dcim"
        "compress=zstd:3"
        "noatime"
        "ssd"
        "space_cache=v2"
      ];
    };
    "/home/y0usaf/Music" = {
      device = "/dev/disk/by-uuid/9df24ce7-8abe-4a4b-9c9d-1a5c1c894051";
      fsType = "btrfs";
      options = [
        "subvol=@music"
        "compress=zstd:3"
        "noatime"
        "ssd"
        "space_cache=v2"
      ];
    };
  };
  zramSwap = {
    enable = true;
    memoryPercent = 50;
    algorithm = "zstd";
  };

  boot.kernel.sysctl."vm.swappiness" = 180;

  swapDevices = [];
  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  powerManagement = {
    enable = true;
  };
}
