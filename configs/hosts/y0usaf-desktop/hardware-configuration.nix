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
      options = ["subvol=@"];
    };
    "/home" = {
      device = "/dev/disk/by-uuid/32ad19b5-88df-4e63-92d2-d5a150ad65c5";
      fsType = "btrfs";
      options = ["subvol=@home"];
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/31F2-1AE7";
      fsType = "vfat";
      options = ["fmask=0077" "dmask=0077"];
    };
    "/home/y0usaf/Pictures" = {
      device = "/dev/disk/by-uuid/9df24ce7-8abe-4a4b-9c9d-1a5c1c894051";
      fsType = "btrfs";
      options = ["subvol=@pictures"];
    };
    "/home/y0usaf/DCIM" = {
      device = "/dev/disk/by-uuid/9df24ce7-8abe-4a4b-9c9d-1a5c1c894051";
      fsType = "btrfs";
      options = ["subvol=@dcim"];
    };
    "/home/y0usaf/Music" = {
      device = "/dev/disk/by-uuid/9df24ce7-8abe-4a4b-9c9d-1a5c1c894051";
      fsType = "btrfs";
      options = ["subvol=@music"];
    };
    "/home/y0usaf/.local/share/Steam" = {
      device = "/dev/disk/by-uuid/9df24ce7-8abe-4a4b-9c9d-1a5c1c894051";
      fsType = "btrfs";
      options = ["subvol=@steam"];
    };
    "/swap" = {
      device = "/dev/disk/by-uuid/32ad19b5-88df-4e63-92d2-d5a150ad65c5";
      fsType = "btrfs";
      options = ["subvol=@swap" "nodatacow"];
    };
    "/home/y0usaf/.cache" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = ["size=2G" "uid=1001" "gid=100" "mode=0755"];
    };
  };
  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 96768;
    }
  ];
  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  powerManagement = {
    enable = true;
  };
}
