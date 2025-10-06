# Hardware configuration for y0usaf-server
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
    initrd.availableKernelModules = ["xhci_pci" "ahci" "sd_mod"];
    initrd.kernelModules = [];
    kernelModules = ["kvm-intel"];
    extraModulePackages = [];
    kernel.sysctl."vm.swappiness" = 100;
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/9dfc38c4-5c75-471d-9106-80ff9175ab92";
    fsType = "btrfs";
    options = ["subvol=@"];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/9dfc38c4-5c75-471d-9106-80ff9175ab92";
    fsType = "btrfs";
    options = ["subvol=@home"];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/41B0-E342";
    fsType = "vfat";
    options = ["fmask=0022" "dmask=0022"];
  };

  fileSystems."/home/y0usaf/Music" = {
    device = "/dev/disk/by-uuid/9dfc38c4-5c75-471d-9106-80ff9175ab92";
    fsType = "btrfs";
    options = ["subvol=@music"];
  };

  fileSystems."/home/y0usaf/DCIM" = {
    device = "/dev/disk/by-uuid/9dfc38c4-5c75-471d-9106-80ff9175ab92";
    fsType = "btrfs";
    options = ["subvol=@dcim"];
  };

  fileSystems."/home/y0usaf/Pictures" = {
    device = "/dev/disk/by-uuid/9dfc38c4-5c75-471d-9106-80ff9175ab92";
    fsType = "btrfs";
    options = ["subvol=@pictures"];
  };

  zramSwap = {
    enable = true;
    memoryPercent = 50;
    algorithm = "zstd";
  };

  swapDevices = [];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
