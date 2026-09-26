{
  config,
  lib,
  pkgs,
  ...
}: let
  diskUuid = "9dfc38c4-5c75-471d-9106-80ff9175ab92";
  kmsgDump = tag: cmds: ''
    {
      ${cmds}
    } 2>&1 | while IFS= read -r line; do
      echo "${tag}: $line" > /dev/kmsg || true
    done
  '';
in {
  networking.hostName = "y0usaf-server";

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "sd_mod"
        "nvme"
        "r8169"
        "igc"
        "e1000e"
      ];

      finit.tasks.initrd-diag = {
        description = "initrd diagnostics to kmsg";
        script = ''
          sleep 3
          ${kmsgDump "finix-initrd" ''
            echo "userspace is up"
            cat /proc/partitions
            ls /dev/disk/by-uuid 2>&1 || echo "no by-uuid dir"
          ''}
          for _ in $(seq 1 60); do
            if [ -e /dev/disk/by-uuid/${diskUuid} ]; then
              echo "finix-initrd: by-uuid symlink present" > /dev/kmsg || true
              exit 0
            fi
            sleep 1
          done
          echo "finix-initrd: by-uuid symlink NEVER appeared" > /dev/kmsg || true
        '';
      };
    };
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

  environment = {
    etc."modprobe.d/finix-server-blacklist.conf".text = ''
      blacklist iTCO_wdt
      blacklist iTCO_vendor_support
    '';
    etc."finix-stage2".text = "persistent\n";
    systemPackages = [
      pkgs.nix
      pkgs.efibootmgr
    ];
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

    "/var/log" = (dir: {
      device = "/persist${dir}";
      fsType = "btrfs";
      options = ["bind"];
      neededForBoot = true;
    }) "/var/log";
  };

  services = {
    getty = {
      enable = true;
      ttys = ["tty1" "ttyS0"];
    };
    nix-daemon = {
      settings = {
        substituters = ["http://127.0.0.1:8787/cache"];
        trusted-public-keys = ["cache:lPd94Ltnv0ZYpkoK5UtQi/VrGkEtHRT7Af6jUzy3PLA="];
        connect-timeout = 5;
      };
    };
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
      stage2-diag = {
        description = "stage-2 diagnostics to kmsg";
        command = pkgs.writeShellScript "stage2-diag" ''
          sleep 30
          ${kmsgDump "finix-stage2" ''
            ${config.finit.package}/bin/initctl status 2>&1
            ${pkgs.iproute2}/bin/ip -4 -br addr 2>&1
          ''}
        '';
        log = true;
      };
      boot-breadcrumb = {
        description = "persist boot breadcrumbs";
        command = "${pkgs.writeShellScript "boot-breadcrumb" ''
          set -u
          export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.util-linux pkgs.iproute2 pkgs.findutils]}

          snapshot() {
            echo "==== $1 $(${pkgs.coreutils}/bin/date -u +%Y-%m-%dT%H:%M:%SZ) ===="
            echo '---- cmdline ----'
            ${pkgs.coreutils}/bin/cat /proc/cmdline
            echo '---- ip addr ----'
            ${pkgs.iproute2}/bin/ip -4 -br addr 2>&1 || true
            echo '---- routes ----'
            ${pkgs.iproute2}/bin/ip route 2>&1 || true
            echo '---- initctl status ----'
            ${config.finit.package}/bin/initctl status 2>&1 || true
            echo '---- mounts ----'
            ${pkgs.util-linux}/bin/findmnt 2>&1 || true
            echo '---- dmesg ----'
            ${pkgs.util-linux}/bin/dmesg 2>&1 || true
          }

          for _ in $(seq 1 120); do
            ${pkgs.util-linux}/bin/mountpoint -q /persist && break
            sleep 1
          done

          if ! ${pkgs.util-linux}/bin/mountpoint -q /persist; then
            echo "boot-breadcrumb: /persist never mounted" >&2
            exit 1
          fi

          outdir=/persist/finix-boot
          ${pkgs.coreutils}/bin/mkdir -p "$outdir"
          ts=$(${pkgs.coreutils}/bin/date -u +%Y-%m-%dT%H-%M-%SZ)

          snapshot early > "$outdir/boot-$ts.log" 2>&1 || true
          ${pkgs.coreutils}/bin/sync || true

          sleep 60
          snapshot late >> "$outdir/boot-$ts.log" 2>&1 || true
          ${pkgs.coreutils}/bin/sync || true

          cd "$outdir"
          ${pkgs.coreutils}/bin/ls -1t boot-*.log 2>/dev/null \
            | ${pkgs.coreutils}/bin/tail -n +21 \
            | ${pkgs.findutils}/bin/xargs -r ${pkgs.coreutils}/bin/rm -f
        ''}";
        log = true;
      };
    };
    services.kmsg-recorder = {
      description = "kmsg flight recorder to /persist";
      log = true;
      command = pkgs.writeShellScript "kmsg-recorder" ''
        export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.util-linux pkgs.findutils]}
        mnt=/run/kmsg-persist
        mkdir -p "$mnt"
        until mountpoint -q "$mnt"; do
          for dev in /dev/disk/by-uuid/${diskUuid} /dev/sda2 /dev/nvme0n1p2; do
            [ -b "$dev" ] || continue
            mount -t btrfs -o subvol=@persist,commit=1 "$dev" "$mnt" 2>/dev/null && break 2
          done
          sleep 1
        done
        d="$mnt/finix-boot"
        mkdir -p "$d"
        ls -1t "$d"/kmsg-*.log 2>/dev/null | tail -n +21 | xargs -r rm -f
        ts=$(date -u +%Y-%m-%dT%H-%M-%SZ)
        echo "kmsg-recorder: writing to $d/kmsg-$ts.log" > /dev/kmsg
        exec cat /dev/kmsg > "$d/kmsg-$ts.log"
      '';
    };
  };
}
