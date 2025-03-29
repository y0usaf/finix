#===============================================================================
#                      🖥️ Hardware Configuration 🖥️
#===============================================================================
# 💽 Storage and filesystems
# 🎮 Gaming directories
# 🎵 Media mounts
# 🔌 Boot and kernel modules
# 🌐 Network interfaces
#===============================================================================
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

  #── 🔌 Boot Configuration ─────────────────#
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

  #── 💽 Root Filesystem ──────────────────#
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/32ad19b5-88df-4e63-92d2-d5a150ad65c5";
    fsType = "btrfs";
    options = ["subvol=@"];
  };

  #── 🏠 Home Directory ──────────────────#
  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/32ad19b5-88df-4e63-92d2-d5a150ad65c5";
    fsType = "btrfs";
    options = ["subvol=@home"];
  };

  #── 🔄 Boot Partition ─────────────────#
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/31F2-1AE7";
    fsType = "vfat";
    options = ["fmask=0077" "dmask=0077"];
  };

  #── 📸 Pictures Directory ─────────────#
  fileSystems."/home/y0usaf/Pictures" = {
    device = "/dev/disk/by-uuid/9df24ce7-8abe-4a4b-9c9d-1a5c1c894051";
    fsType = "btrfs";
    options = ["subvol=@pictures"];
  };

  #── 📷 DCIM Directory ──────────────────#
  fileSystems."/home/y0usaf/DCIM" = {
    device = "/dev/disk/by-uuid/9df24ce7-8abe-4a4b-9c9d-1a5c1c894051";
    fsType = "btrfs";
    options = ["subvol=@dcim"];
  };

  #── 🎵 Music Directory ─────────────────#
  fileSystems."/home/y0usaf/Music" = {
    device = "/dev/disk/by-uuid/9df24ce7-8abe-4a4b-9c9d-1a5c1c894051";
    fsType = "btrfs";
    options = ["subvol=@music"];
  };

  #── 🎮 Steam Directory ─────────────────#
  fileSystems."/home/y0usaf/.local/share/Steam" = {
    device = "/dev/disk/by-uuid/9df24ce7-8abe-4a4b-9c9d-1a5c1c894051";
    fsType = "btrfs";
    options = ["subvol=@steam"];
  };

  #── 💾 Swap Configuration ──────────────#
  fileSystems."/swap" = {
    device = "/dev/disk/by-uuid/32ad19b5-88df-4e63-92d2-d5a150ad65c5";
    fsType = "btrfs";
    options = ["subvol=@swap" "nodatacow"];
  };

  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 96768; # Increased to match RAM size for hibernation (96GB + 768MB)
    }
  ];

  #── 🌐 Network Configuration ───────────#
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.eno1.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp96s0.useDHCP = lib.mkDefault true;

  #── 💻 Platform Settings ───────────────#
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  powerManagement = {
    enable = true;
    # Further options such as laptop mode, backlight controls, etc.
  };
}
