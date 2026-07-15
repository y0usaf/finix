# Kexec-era drivers + VM runner + beacon initrd. RETIRED from active use
# after the 2026-07-15 bootloader takeover (ESP island is the boot path);
# kept buildable for reference and because the beacon pattern is hard-won
# (see NOTES.md "Hard-won debugging infrastructure").
{
  pkgs,
  lib,
  serverVm,
  serverTrial,
  serverPersistent,
}: rec {
  runVmScript = pkgs.writeShellScriptBin "run-finix-server-vm" ''
    exec ${lib.escapeShellArgs serverVm.config.virtualisation.qemu.argv} "$@"
  '';

  # Pre-finit beacon: the only netconsole that has proven reliable on the
  # real server (finit's own initrd tasks race NIC bring-up). Wraps /init in
  # a tiny shell script that loads the NIC driver + netconsole and emits
  # progress markers to /dev/kmsg before handing off to finit untouched.
  # NOTE: the initrd's standalone `sh` has no default PATH - set it.
  beaconInit = pkgs.writeScript "beacon-init" ''
    #!/bin/sh
    PATH=/bin
    export PATH
    mkdir -p /proc /sys /dev
    mount -t proc proc /proc 2>/dev/null
    mount -t sysfs sysfs /sys 2>/dev/null
    mount -t devtmpfs devtmpfs /dev 2>/dev/null
    for m in r8169 igc e1000e; do modprobe "$m" 2>/dev/null; done
    sleep 2
    for _ in 1 2 3 4 5; do
      for d in /sys/class/net/*; do
        n=$(basename "$d")
        [ "$n" = lo ] && continue
        if modprobe netconsole "netconsole=+6665@192.168.2.66/$n,6666@192.168.2.28/58:11:22:b7:f0:29" 2>/dev/null; then
          echo "beacon: netconsole up on $n" > /dev/kmsg
          break 2
        fi
      done
      sleep 1
    done
    echo "beacon: exec finit" > /dev/kmsg
    exec /init-orig "$@"
  '';

  beaconInitrd =
    pkgs.runCommand "finix-trial-initrd-beacon" {
      nativeBuildInputs = [pkgs.cpio pkgs.zstd];
    } ''
      mkdir root $out
      cd root
      cat ${serverTrial.config.system.topLevel}/initrd | zstd -dc | cpio -idm --no-absolute-filenames --quiet
      mv init init-orig
      cp ${beaconInit} init
      chmod +x init
      find . -mindepth 1 | cpio -o -H newc --owner=+0:+0 --quiet | zstd -3 > $out/initrd
    '';

  # Desktop-side driver for the guarded bare-metal trial. Refuses to kexec
  # unless the hardware watchdog exists and systemd is configured to arm it
  # across the kexec (see hosts/y0usaf-server/finix-guard.nix).
  trialScript = pkgs.writeShellScriptBin "finix-server-trial" ''
    set -euo pipefail

    host="''${1:-server}"
    system_path='${serverTrial.config.system.topLevel}'
    bootjson="$system_path/boot.json"

    kernel="$(${pkgs.jq}/bin/jq -r '.["org.nixos.bootspec.v1"].kernel' "$bootjson")"
    initrd='${beaconInitrd}/initrd'
    init="$(${pkgs.jq}/bin/jq -r '.["org.nixos.bootspec.v1"].init' "$bootjson")"
    kernel_params="$(${pkgs.jq}/bin/jq -r '.["org.nixos.bootspec.v1"].kernelParams | join(" ")' "$bootjson")"
    cmdline="init=$init $kernel_params"

    echo "==> copying finix closure to $host"
    nix copy --to "ssh://$host" "$system_path" '${beaconInitrd}'

    echo "==> verifying guards and starting guarded kexec"
    ssh "$host" "sudo bash -s -- '$kernel' '$initrd' '$cmdline' '$system_path'" <<'EOF'
    set -euo pipefail
    kernel=$1 initrd=$2 cmdline=$3 system=$4

    modprobe intel_oc_wdt 2>/dev/null || true
    if ! [ -c /dev/watchdog0 ]; then
      echo "ABORT: /dev/watchdog0 missing - refusing unguarded kexec" >&2
      exit 1
    fi

    wd_usec="$(systemctl show -p KExecWatchdogUSec --value)"
    case "$wd_usec" in
      ""|0|infinity)
        echo "ABORT: KExecWatchdogSec not configured (systemd.watchdog.kexecTime) - refusing unguarded kexec" >&2
        exit 1
        ;;
    esac
    echo "watchdog: /dev/watchdog0 present, kexec arming = $wd_usec"

    # Protect the trial closure from nix-collect-garbage on the server.
    nix-store --realise "$system" --add-root /nix/var/nix/gcroots/finix-trial >/dev/null

    kexec -l "$kernel" --initrd="$initrd" --command-line="$cmdline"
    sync
    echo "jumping to finix..."
    systemctl kexec
    EOF

    cat <<'MSG'

    kexec initiated. Guards active:
      - HW watchdog armed across the jump (hang -> reset -> NixOS)
      - panic=30 / oops=panic / lockup panics (crash -> reboot -> NixOS)
      - auto-return to NixOS after 10 min unless you run:
          ssh y0usaf@<ip> 'touch /persist/finix-trial/keep'
      - return manually: ssh y0usaf@<ip> 'sudo initctl reboot'
      - post-mortem after a failed trial: /persist/finix-trial/boot-*.log

    The trial system uses DHCP with static fallback 192.168.2.66.
    MSG
  '';

  persistentKexecScript = pkgs.writeShellScriptBin "finix-server-persistent-kexec" ''
    set -euo pipefail

    host="''${1:-server}"
    system_path='${serverPersistent.config.system.topLevel}'
    bootjson="$system_path/boot.json"
    kernel="$(${pkgs.jq}/bin/jq -r '.["org.nixos.bootspec.v1"].kernel' "$bootjson")"
    initrd="$system_path/initrd"
    init="$(${pkgs.jq}/bin/jq -r '.["org.nixos.bootspec.v1"].init' "$bootjson")"
    kernel_params="$(${pkgs.jq}/bin/jq -r '.["org.nixos.bootspec.v1"].kernelParams | join(" ")' "$bootjson")"
    cmdline="init=$init $kernel_params"

    echo "==> copying persistent finix closure to $host"
    nix copy --to "ssh://$host" "$system_path"

    echo "==> verifying guards and starting persistent kexec"
    ssh "$host" "sudo bash -s -- '$kernel' '$initrd' '$cmdline' '$system_path'" <<'EOF'
    set -euo pipefail
    kernel=$1 initrd=$2 cmdline=$3 system=$4

    modprobe intel_oc_wdt 2>/dev/null || true
    if ! [ -c /dev/watchdog0 ]; then
      echo "ABORT: /dev/watchdog0 missing - refusing unguarded kexec" >&2
      exit 1
    fi

    wd_usec="$(systemctl show -p KExecWatchdogUSec --value)"
    case "$wd_usec" in
      ""|0|infinity)
        echo "ABORT: KExecWatchdogSec not configured - refusing unguarded kexec" >&2
        exit 1
        ;;
    esac
    echo "watchdog: /dev/watchdog0 present, kexec arming = $wd_usec"

    nix-store --realise "$system" --add-root /nix/var/nix/gcroots/finix-persistent >/dev/null
    kexec -l "$kernel" --initrd="$initrd" --command-line="$cmdline"
    sync
    echo "jumping to persistent finix..."
    systemctl kexec
    EOF

    cat <<'MSG'

    persistent finix kexec initiated:
      - HW watchdog + panic guards return to NixOS on failure
      - no auto-return timer; this system is intended to stay up
      - manual return: ssh y0usaf@<ip> 'sudo initctl reboot'

    MSG
  '';
}
