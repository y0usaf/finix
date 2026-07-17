# Boot diagnostics for finix hosts: kmsg flight recorder + boot breadcrumbs
# + initrd/stage-2 kmsg markers. Parameterized port of the machinery proven
# on y0usaf-server (see NOTES.md "Hard-won debugging infrastructure"); the
# server still carries its original inline copy — migrate it here on its
# next planned deploy, not before.
#
# Design constraints carried over:
#   - recorder is a supervised finit SERVICE (finit reaps a run task's
#     cgroup on exit, killing backgrounded writers)
#   - recorder self-mounts the persist subvolume (no fstab dependency) with
#     commit=1 so logs survive hard freezes without a sync loop
#   - breadcrumb waits for the fstab /persist mount instead
#   - kmsg markers survive in the recorder log even when syslog never
#     started (the 2026-07-15 warm-reboot hang left zero logs otherwise)
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.finix.diagnostics;

  kmsgDump = tag: cmds: ''
    {
      ${cmds}
    } 2>&1 | while IFS= read -r line; do
      echo "${tag}: $line" > /dev/kmsg || true
    done
  '';

  breadcrumb = pkgs.writeShellScript "boot-breadcrumb" ''
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

    # Wait for /persist; the fstab mount task runs early in stage 2.
    for _ in $(seq 1 120); do
      ${pkgs.util-linux}/bin/mountpoint -q /persist && break
      sleep 1
    done

    if ! ${pkgs.util-linux}/bin/mountpoint -q /persist; then
      echo "boot-breadcrumb: /persist never mounted" >&2
      exit 1
    fi

    outdir=/persist/${cfg.logDir}
    ${pkgs.coreutils}/bin/mkdir -p "$outdir"
    ts=$(${pkgs.coreutils}/bin/date -u +%Y-%m-%dT%H-%M-%SZ)

    snapshot early > "$outdir/boot-$ts.log" 2>&1 || true
    ${pkgs.coreutils}/bin/sync || true

    # Second snapshot once services settled.
    sleep 60
    snapshot late >> "$outdir/boot-$ts.log" 2>&1 || true
    ${pkgs.coreutils}/bin/sync || true

    cd "$outdir"
    ${pkgs.coreutils}/bin/ls -1t boot-*.log 2>/dev/null \
      | ${pkgs.coreutils}/bin/tail -n +21 \
      | ${pkgs.findutils}/bin/xargs -r ${pkgs.coreutils}/bin/rm -f
  '';
in {
  options.finix.diagnostics = {
    enable = lib.mkEnableOption "kmsg flight recorder + boot breadcrumbs";

    diskUuid = lib.mkOption {
      type = lib.types.str;
      description = "btrfs disk UUID carrying the persist subvolume.";
    };

    persistSubvol = lib.mkOption {
      type = lib.types.str;
      default = "@persist";
      description = "btrfs subvolume the recorder self-mounts for log storage.";
    };

    fallbackDevices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Raw device paths tried when the by-uuid symlink is absent.";
    };

    logDir = lib.mkOption {
      type = lib.types.str;
      default = "finix-boot";
      description = "Directory under /persist receiving kmsg-*.log + boot-*.log.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Progress markers into /dev/kmsg: visible on the console during a
    # pre-userspace hang and replayed into the flight recorder log on a
    # healthy boot.
    boot.initrd.finit.tasks.initrd-diag = {
      description = "initrd diagnostics to kmsg";
      script = ''
        sleep 3
        ${kmsgDump "finix-initrd" ''
          echo "userspace is up"
          cat /proc/partitions
          ls /dev/disk/by-uuid 2>&1 || echo "no by-uuid dir"
        ''}
        # Report whether the root disk symlink ever appears.
        for _ in $(seq 1 60); do
          if [ -e /dev/disk/by-uuid/${cfg.diskUuid} ]; then
            echo "finix-initrd: by-uuid symlink present" > /dev/kmsg || true
            exit 0
          fi
          sleep 1
        done
        echo "finix-initrd: by-uuid symlink NEVER appeared" > /dev/kmsg || true
      '';
    };

    # Stage-2 status dump into the kmsg stream (and thus the recorder log).
    finit.tasks.stage2-diag = {
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

    # Flight recorder: stream /dev/kmsg (full replay from boot + follow) to
    # /persist. Self-sufficient by design; see header.
    finit.services.kmsg-recorder = {
      description = "kmsg flight recorder to /persist";
      log = true;
      command = pkgs.writeShellScript "kmsg-recorder" ''
        export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.util-linux pkgs.findutils]}
        mnt=/run/kmsg-persist
        mkdir -p "$mnt"
        until mountpoint -q "$mnt"; do
          for dev in /dev/disk/by-uuid/${cfg.diskUuid} ${lib.concatStringsSep " " cfg.fallbackDevices}; do
            [ -b "$dev" ] || continue
            mount -t btrfs -o subvol=${cfg.persistSubvol},commit=1 "$dev" "$mnt" 2>/dev/null && break 2
          done
          sleep 1
        done
        d="$mnt/${cfg.logDir}"
        mkdir -p "$d"
        # This runs on every boot forever: keep the newest 20 logs.
        ls -1t "$d"/kmsg-*.log 2>/dev/null | tail -n +21 | xargs -r rm -f
        ts=$(date -u +%Y-%m-%dT%H-%M-%SZ)
        echo "kmsg-recorder: writing to $d/kmsg-$ts.log" > /dev/kmsg
        # /dev/kmsg replays the entire buffer from boot, then follows.
        exec cat /dev/kmsg > "$d/kmsg-$ts.log"
      '';
    };

    # Persist post-mortem snapshots where NixOS can read them. Unconditional:
    # even a partial boot should leave traces.
    finit.tasks.boot-breadcrumb = {
      description = "persist boot breadcrumbs";
      command = "${breadcrumb}";
      log = true;
    };
  };
}
