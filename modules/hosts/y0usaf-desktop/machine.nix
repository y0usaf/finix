{
  config,
  lib,
  pkgs,
  ...
}: let
  diskUuid = "32ad19b5-88df-4e63-92d2-d5a150ad65c5";

  subvolMount = subvol: {
    device = "/dev/disk/by-uuid/${diskUuid}";
    fsType = "btrfs";
    options = ["subvol=${subvol}" "compress=zstd:3" "noatime" "ssd" "space_cache=v2"];
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
      "/root"
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
      options = ["subvolid=5" "compress=zstd:3" "noatime" "ssd" "space_cache=v2"];
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

  user = {
    appearance = {
      dpi = 109;
      termFontSize = 16;
      hyprcursorSize = 36;
    };

    paths.wallpapers = "${config.user.homeDirectory}/DCIM/Wallpapers/32_9/";

    ui.tomoe = {
      displays = {
        "DP-4" = {
          mode = [5120 1440];
          icc = "${pkgs.runCommand "ls49ag95.icc" {} "${lib.getExe' pkgs.colord "cd-create-profile"} -o $out ${./ls49ag95.iccprofile.xml}"}";
        };
        "HDMI-A-2" = {
          mode = [1920 1080 60];
          position = [5120 0];
        };
      };

      bar.modules = ["cpu" "memory" "gpu" "time" "date"];
    };

    gaming = {
      p4g.enable = true;
      solo-leveling-arise.enable = true;
      aethermancer.enable = true;
      elden-ring.enable = true;
      proton.enable = true;
      runelite.enable = true;
    };

    tools."3d-printing".enable = true;
  };
}
