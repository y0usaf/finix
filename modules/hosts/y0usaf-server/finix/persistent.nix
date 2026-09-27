{
  lib,
  pkgs,
  ...
}: let
  diskUuid = "9dfc38c4-5c75-471d-9106-80ff9175ab92";
in {
  networking.hostName = "y0usaf-server";

  finix.diagnostics = {
    enable = true;
    inherit diskUuid;
    fallbackDevices = ["/dev/sda2" "/dev/nvme0n1p2"];
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    initrd.availableKernelModules = [
      "xhci_pci"
      "ahci"
      "sd_mod"
      "nvme"
      "r8169"
      "igc"
      "e1000e"
    ];
    kernelModules = [
      "intel_oc_wdt"
      "r8169"
      "igc"
      "e1000e"
    ];
    supportedFilesystems.efivarfs.enable = true;
    kernelParams = [
      "console=tty0"
      "panic=30"
      "oops=panic"
      "softlockup_panic=1"
      "hung_task_panic=1"
    ];
  };

  environment.etc = {
    "modprobe.d/finix-server-blacklist.conf".text = ''
      blacklist iTCO_wdt
      blacklist iTCO_vendor_support
    '';
    "finix-stage2".text = "persistent\n";
  };

  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = ["mode=755" "size=2G"];
    };

    "/nix" = {
      device = "/dev/disk/by-uuid/${diskUuid}";
      fsType = "btrfs";
      options = ["subvol=@nix" "noatime"];
      neededForBoot = true;
    };

    "/persist" = {
      device = "/dev/disk/by-uuid/${diskUuid}";
      fsType = "btrfs";
      options = ["subvol=@persist" "compress=zstd" "noatime"];
      neededForBoot = true;
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/41B0-E342";
      fsType = "vfat";
      options = ["umask=0077" "noatime"];
      neededForBoot = true;
    };

    "/var/log" = {
      device = "/persist/var/log";
      fsType = "btrfs";
      options = ["bind"];
      neededForBoot = true;
    };
  };

  services = {
    getty.ttys = ["tty1" "ttyS0"];
    nix-daemon.settings.trusted-public-keys = ["cache:lPd94Ltnv0ZYpkoK5UtQi/VrGkEtHRT7Af6jUzy3PLA="];
  };

  finit = {
    services.watchdog-keepalive = {
      description = "persistent watchdog keepalive";
      command = "${pkgs.writeShellScript "persistent-watchdog-keepalive" ''
        set -u
        export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.kmod]}

        ${pkgs.kmod}/bin/modprobe intel_oc_wdt 2>/dev/null || true

        for _ in $(seq 1 30); do
          set -- /dev/watchdog[0-9]*
          [ -c "$1" ] && break
          sleep 1
        done

        devs=()
        for d in /dev/watchdog[0-9]*; do
          [ -c "$d" ] || continue
          if exec {fd}>"$d"; then
            devs+=("$fd")
          fi
        done

        if [ "''${#devs[@]}" -eq 0 ]; then
          echo "watchdog-keepalive: no watchdog devices found" >&2
          exit 1
        fi

        trap 'for fd in "''${devs[@]}"; do printf V >&"$fd"; done; exit 0' TERM INT
        while true; do
          for fd in "''${devs[@]}"; do
            printf '\0' >&"$fd"
          done
          sleep 5
        done
      ''}";
      log = true;
    };
    tasks = {
      net-fallback = {
        description = "static IP fallback if DHCP fails";
        command = "${pkgs.writeShellScript "persistent-net-fallback" ''
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
          ${pkgs.iproute2}/bin/ip addr replace 192.168.2.66/24 dev "$iface" || true
          ${pkgs.iproute2}/bin/ip route replace default via 192.168.2.1 dev "$iface" || true
          printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf || true
        ''}";
        conditions = ["net/lo/up"];
        log = true;
      };
      bootnext-deadman = {
        description = "EFI BootNext dead-man switch for the Finix island";
        command = "${pkgs.writeShellScript "persistent-bootnext-deadman" ''
          set -u
          export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.util-linux pkgs.efibootmgr pkgs.gnugrep pkgs.gnused pkgs.iproute2]}

          mountpoint -q /sys/firmware/efi/efivars \
            || mount -t efivarfs efivarfs /sys/firmware/efi/efivars \
            || { echo "bootnext-deadman: no efivars; not armed" >&2; exit 1; }

          island="$(efibootmgr | sed -n 's/^Boot\([0-9A-F]\{4\}\)[^ ]* Finix\t.*/\1/p' | head -n1)"
          if [ -z "$island" ]; then
            echo "bootnext-deadman: no Finix EFI entry; not armed" >&2
            exit 1
          fi
          efibootmgr -q -n "$island" || { echo "bootnext-deadman: arming failed" >&2; exit 1; }
          echo "bootnext-deadman: armed BootNext=Boot$island (Finix island)"

          ok=0
          for _ in $(seq 1 60); do
            if ss -ltn 2>/dev/null | grep -q ':2200 '; then
              ok=$((ok + 1))
            else
              ok=0
            fi
            if [ "$ok" -ge 12 ]; then
              efibootmgr -q -N || true
              echo "bootnext-deadman: healthy, BootNext cleared"
              exit 0
            fi
            sleep 10
          done
          echo "bootnext-deadman: health timeout; BootNext stays armed (next boot = Finix island)" >&2
          exit 1
        ''}";
        log = true;
      };
      bootorder-assert = {
        description = "assert stable Limine EFI BootOrder and fallback";
        command = "${pkgs.writeShellScript "persistent-bootorder-assert" ''
          set -eu
          export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.util-linux pkgs.efibootmgr pkgs.gnused pkgs.gnugrep pkgs.diffutils]}

          mountpoint -q /sys/firmware/efi/efivars \
            || mount -t efivarfs efivarfs /sys/firmware/efi/efivars \
            || { echo "bootorder-assert: no efivars" >&2; exit 1; }

          lim="$(efibootmgr | sed -n 's/^Boot\([0-9A-Fa-f]\{4\}\)[^ ]*[[:space:]]\+Limine[[:space:]].*/\1/p' | head -n1)"
          fin="$(efibootmgr | sed -n 's/^Boot\([0-9A-Fa-f]\{4\}\)[^ ]*[[:space:]]\+Finix[[:space:]].*/\1/p' | head -n1)"
          if [ -z "$lim" ] || [ -z "$fin" ]; then
            echo "bootorder-assert: missing Limine or Finix EFI entry" >&2
            exit 1
          fi

          current="$(efibootmgr | sed -n 's/^BootOrder: //p')"
          desired="$lim,$fin"
          oldIFS="$IFS"
          IFS=,
          for id in $current; do
            [ "$id" = "$lim" ] || [ "$id" = "$fin" ] || desired="$desired,$id"
          done
          IFS="$oldIFS"
          echo "bootorder-assert: current=$current desired=$desired"
          if [ "$current" != "$desired" ]; then
            efibootmgr -q -o "$desired"
            after="$(efibootmgr | sed -n 's/^BootOrder: //p')"
            echo "bootorder-assert: after=$after"
          fi

          if [ -e /boot/EFI/limine/BOOTX64.EFI ] && [ ! -e /boot/EFI/BOOT/BOOTX64.EFI ] || \
             [ -e /boot/EFI/limine/BOOTX64.EFI ] && ! cmp -s /boot/EFI/limine/BOOTX64.EFI /boot/EFI/BOOT/BOOTX64.EFI; then
            mkdir -p /boot/EFI/BOOT
            cp /boot/EFI/limine/BOOTX64.EFI /boot/EFI/BOOT/BOOTX64.EFI
            sync
            echo "bootorder-assert: synced EFI fallback from enrolled Limine"
          fi
        ''}";
        conditions = ["net/lo/up"];
        log = true;
      };
    };
  };
}
