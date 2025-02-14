{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "usbhid"
        "usb_storage"
        "sd_mod"
        "rtsx_pci_sdmmc"
      ];
      kernelModules = [ ];
    };
    kernelModules = ["kvm-amd"];
    extraModulePackages = [ ];
    
    # Use latest kernel for best hardware support
    kernelPackages = pkgs.linuxPackages_latest;
    
    # Kernel parameters for AMD GPU
    kernelParams = [
      "amdgpu.ppfeaturemask=0xffffffff"  # Enable all power features
      "amdgpu.dpm=1"                      # Enable power management
      "quiet"
      "splash"
    ];
  };

  # File system configuration
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos";  # Adjust this to match your setup
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-label/BOOT";   # Adjust this to match your setup
      fsType = "vfat";
    };
  };

  swapDevices = [
    { device = "/dev/disk/by-label/swap"; } # Adjust this to match your setup
  ];

  # Hardware configuration
  hardware = {
    # AMD CPU configuration
    cpu.amd.updateMicrocode = true;
    
    # AMD GPU configuration
    amdgpu = {
      enable = true;
      loadInInitrd = true;
      opencl = true;
    };
  };

  # High-DPI settings if using the WQHD screen
  hardware.video.hidpi.enable = lib.mkDefault true;

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
} 