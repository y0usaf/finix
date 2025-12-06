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
    initrd.availableKernelModules = ["nvme" "xhci_pci" "usbhid"];
    initrd.kernelModules = [];
    kernelModules = ["kvm-amd"];
    extraModulePackages = [];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/f3d25172-f728-4bb6-a14d-f86e97a6a0e7";
      fsType = "btrfs";
      options = ["subvol=@"];
    };

    "/home" = {
      device = "/dev/disk/by-uuid/f3d25172-f728-4bb6-a14d-f86e97a6a0e7";
      fsType = "btrfs";
      options = ["subvol=@home"];
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/5330-BB8D";
      fsType = "vfat";
      options = ["fmask=0077" "dmask=0077"];
    };
  };

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

  swapDevices = [
    {
      device = "/dev/disk/by-uuid/be858002-6caa-4bca-8160-75cc21c1836e";
      priority = 10;
    }
  ];

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
