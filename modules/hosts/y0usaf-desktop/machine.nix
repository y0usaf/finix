{
  config,
  lib,
  pkgs,
  ...
}: let
  diskUuid = "32ad19b5-88df-4e63-92d2-d5a150ad65c5";

  btrfsOpts = ["compress=zstd:3" "noatime" "ssd" "space_cache=v2"];
  subvolMount = subvol: {
    device = "/dev/disk/by-uuid/${diskUuid}";
    fsType = "btrfs";
    options = ["subvol=${subvol}"] ++ btrfsOpts;
    neededForBoot = true;
  };
in {
  networking.hostName = "y0usaf-desktop";

  finix = {
    diagnostics = {
      inherit diskUuid;
      fallbackDevices = ["/dev/nvme0n1p5"];
    };
    persistence.allowlist.directories = [
      {
        directory = "/root";
        mode = "0700";
      }
      "/var/lib/btrbk"
      "/var/lib/sbctl"
    ];
  };

  hardware = {
    firmware = [pkgs.linux-firmware];
    nvidia = {
      enable = true;
      gsp.enable = false;
    };
  };

  environment.etc."finix-stage2".text = "desktop-phase2.4\n";

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    extraModulePackages = [config.boot.kernelPackages.zenpower config.hardware.nvidia.package.mod];
    initrd.availableKernelModules = [
      "nvme"
      "thunderbolt"
      "xhci_pci"
      "ahci"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];
    kernelModules = [
      "kvm-amd"
      "k10temp"
      "nct6775"
      "zenpower"
      "igc"
    ];
    supportedFilesystems = {
      btrfs.enable = true;
      efivarfs.enable = true;
    };
    kernelParams = [
      "amd_pstate=active"
      "mitigations=off"
      "console=tty0"
      "usbcore.autosuspend=-1"
      "panic=30"
      "oops=panic"
      "softlockup_panic=1"
      "hung_task_panic=1"
      "nvidia.NVreg_UsePageAttributeTable=1"
      "nvidia.NVreg_EnableResizableBar=1"
      "nvidia.NVreg_RegistryDwords=RmEnableAggressiveVblank=1"
      "nvidia_modeset.disable_vrr_memclk_switch=1"
      "nvidia.NVreg_TemporaryFilePath=/var/tmp"
    ];
  };

  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = ["mode=755" "size=4G"];
    };

    "/tmp" = {
      device = "none";
      fsType = "tmpfs";
      options = ["mode=1777" "size=16G" "nosuid" "nodev" "strictatime"];
      neededForBoot = true;
    };

    "/nix" = subvolMount "@nix";
    "/persist" = subvolMount "@persist";
    "/home" = subvolMount "@home";

    "/btrfs" = {
      device = "/dev/disk/by-uuid/${diskUuid}";
      fsType = "btrfs";
      options = ["subvolid=5"] ++ btrfsOpts;
      neededForBoot = true;
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/31F2-1AE7";
      fsType = "vfat";
      options = ["fmask=0077" "dmask=0077" "noatime"];
      neededForBoot = true;
    };

    "/home/y0usaf/.local/share/Steam" = subvolMount "@steam";
    "/home/y0usaf/dev" = subvolMount "@dev";
    "/home/y0usaf/Pictures" = subvolMount "@pictures";
    "/home/y0usaf/DCIM" = subvolMount "@dcim";
    "/home/y0usaf/Music" = subvolMount "@music";
  };

  finit.services.nix-daemon.cgroup.settings."cpu.max" = 2400000;

  services.sysklogd.extraConfig = "*.* @192.168.2.66:514";

  users.users.y0usaf.uid = 1001;
  users.users.root.passwordFile = "/persist/secrets/password-hashes/root";

  finit.tasks.net-fallback = {
    description = "static IP fallback if DHCP fails";
    command = "${pkgs.writeShellScript "desktop-net-fallback" ''
      set -eu
      export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.iproute2 pkgs.gnugrep]}

      find_iface() {
        for dev in /sys/class/net/en* /sys/class/net/eth*; do
          [ -e "$dev" ] || continue
          basename "$dev"
          return 0
        done
        return 1
      }

      for _ in $(seq 1 45); do
        if ${pkgs.iproute2}/bin/ip -4 addr show scope global 2>/dev/null \
          | ${pkgs.gnugrep}/bin/grep -q 'inet '; then
          exit 0
        fi
        sleep 1
      done

      iface="$(find_iface)" || exit 1
      ${pkgs.iproute2}/bin/ip link set "$iface" up || true
      ${pkgs.iproute2}/bin/ip addr replace 192.168.2.28/24 dev "$iface" || true
      ${pkgs.iproute2}/bin/ip route replace default via 192.168.2.1 dev "$iface" || true
      printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf || true
    ''}";
    conditions = ["net/lo/up"];
    log = true;
  };
}
