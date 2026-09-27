{
  config,
  lib,
  pkgs,
  ...
}: let
  userName = config.user.name;
  diskUuid = "6ae685dc-540e-42f2-b30a-104a8aac0e27";
  subvolMount = subvol: {
    device = "/dev/disk/by-uuid/${diskUuid}";
    fsType = "btrfs";
    options = ["subvol=${subvol}" "relatime" "ssd" "discard=async" "space_cache=v2"];
    neededForBoot = true;
  };

  healthPackage = pkgs.writeShellScriptBin "finix-framework-health" ''
    set -u
    export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.gnugrep pkgs.iproute2 pkgs.nftables pkgs.procps pkgs.shadow pkgs.util-linux]}
    failed=0
    check() {
      if "$@"; then
        printf 'ok: %s\n' "$*"
      else
        printf 'FAIL: %s\n' "$*" >&2
        failed=1
      fi
    }
    check test "$(cat /proc/1/comm)" = finit
    check grep -qx framework-trial-1 /etc/finix-stage2
    for mountpoint in /nix /persist /home /boot; do
      check mountpoint -q "$mountpoint"
    done
    check test "$(id -u ${userName})" = 1000
    check sh -c "ip -4 -br address show dev wlp191s0 scope global | grep -q '^wlp191s0.*UP'"
    check sh -c "ip -4 route show default | grep -q '^default '"
    check sh -c "ss -ltn | grep -q ':2222 '"
    check nft list table inet filter
    check test -e /dev/dri/renderD128
    if [ "''${1:-}" = --record ]; then
      out=/persist/finix-framework-boot
      mkdir -p "$out"
      stamp=$(date -u +%Y-%m-%dT%H-%M-%SZ)
      if [ "$failed" = 0 ]; then
        printf '%s\n' "$stamp" > "$out/healthy-$stamp"
      else
        printf '%s\n' "$stamp" > "$out/failed-$stamp"
      fi
      sync
    fi
    exit "$failed"
  '';
in {
  networking.hostName = "y0usaf-framework";

  finix.diagnostics = {
    inherit diskUuid;
    fallbackDevices = ["/dev/nvme0n1p2"];
    logDir = "finix-framework-boot";
  };

  hardware = {
    firmware = [pkgs.linux-firmware];
    cpu.amd.updateMicrocode = true;
  };

  environment = {
    etc = {
      "finix-stage2".text = "framework-trial-1\n";
      "elogind/logind.conf".text = lib.mkForce ''
        [Login]
        HandlePowerKey=poweroff
        HandleLidSwitch=suspend
        HandleLidSwitchExternalPower=suspend
        HandleLidSwitchDocked=ignore
        LidSwitchIgnoreInhibited=no
      '';
    };
    systemPackages = [pkgs.acpi healthPackage];
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

  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = ["mode=755" "size=4G"];
    };
    "/tmp" = {
      device = "none";
      fsType = "tmpfs";
      options = ["mode=1777" "size=8G" "nosuid" "nodev" "strictatime"];
      neededForBoot = true;
    };
    "/nix" = subvolMount "@nix";
    "/persist" = subvolMount "@persist";
    "/home" = subvolMount "@home";
    "/btrfs" = {
      device = "/dev/disk/by-uuid/${diskUuid}";
      fsType = "btrfs";
      options = ["subvolid=5" "relatime" "ssd" "discard=async" "space_cache=v2"];
      neededForBoot = true;
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/6951-2BA6";
      fsType = "vfat";
      options = ["fmask=0077" "dmask=0077"];
      neededForBoot = true;
    };
    "/home/${userName}/.local/share/Steam" = subvolMount "@steam";
    "/home/${userName}/dev" = subvolMount "@dev";
  };

  services = {
    elogind.enable = true;
    power-profiles-daemon = {
      enable = true;
      extraGroups = [config.services.seatd.group];
    };
    fwupd.enable = true;
    docker.enable = true;
    nix-daemon.settings = {
      sandbox = true;
      auto-optimise-store = true;
      substituters = lib.mkBefore ["https://cache.nixos.org"];
    };
  };

  programs = {
    brightnessctl.enable = true;
    zzz.enable = true;
  };

  users.users.${userName} = {
    uid = 1000;
    extraGroups = ["docker"];
  };

  finit.tasks.framework-boot-health = {
    description = "record first-boot health after network and services settle";
    command = "${pkgs.writeShellScript "framework-boot-health" ''
      export PATH=${lib.makeBinPath [pkgs.coreutils]}
      for _ in $(seq 1 120); do
        if ${healthPackage}/bin/finix-framework-health; then
          exec ${healthPackage}/bin/finix-framework-health --record
        fi
        sleep 5
      done
      exec ${healthPackage}/bin/finix-framework-health --record
    ''}";
    log = true;
  };
}
