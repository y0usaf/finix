{
  config,
  lib,
  pkgs,
  ...
}: let
  diskUuid = "6ae685dc-540e-42f2-b30a-104a8aac0e27";
  shared = import ../shared.nix {inherit lib;};
  btrfs = shared.btrfs diskUuid ["relatime" "ssd" "discard=async" "space_cache=v2"];
in {
  finix.diagnostics = {
    inherit diskUuid;
    fallbackDevices = ["/dev/nvme0n1p2"];
    logDir = "finix-framework-boot";
  };

  hardware = {
    firmware = [pkgs.linux-firmware];
    cpu.amd.updateMicrocode = true;
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    initrd.availableKernelModules = ["nvme" "xhci_pci" "thunderbolt" "usbhid" "usb_storage" "sd_mod"];
    kernelModules = ["kvm-amd" "amdgpu"];
    supportedFilesystems.efivarfs.enable = true;
    kernelParams = [
      "amd_pstate=active"
      "amdgpu.ppfeaturemask=0xffffffff"
      "amdgpu.dpm=1"
      "console=tty0"
      "panic=30"
      "oops=panic"
      "softlockup_panic=1"
      "hung_task_panic=1"
    ];
  };

  fileSystems = shared.fileSystems {
    rootSize = "4G";
    tmpSize = "8G";
    boot = {
      uuid = "6951-2BA6";
      options = ["fmask=0077" "dmask=0077"];
    };
    mounts = {
      "/nix" = btrfs "subvol=@nix";
      "/persist" = btrfs "subvol=@persist";
      "/home" = btrfs "subvol=@home";
      "/btrfs" = btrfs "subvolid=5";
      "/home/${config.user.name}/.local/share/Steam" = btrfs "subvol=@steam";
      "/home/${config.user.name}/dev" = btrfs "subvol=@dev";
    };
  };

  user.ui.tomoe.displays."eDP-1".scale = 1;
}
