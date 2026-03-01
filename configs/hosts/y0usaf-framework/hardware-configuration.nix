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

  boot.tmp = {
    useTmpfs = true;
    tmpfsSize = "25%";
  };

  boot.kernel.sysctl."vm.swappiness" = 180;

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
