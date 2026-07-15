# Bare-metal finix trial for y0usaf-server, booted via kexec from the
# running NixOS system. Designed so every failure mode returns to NixOS
# without physical access:
#
#   guard 0: kexec touches neither the bootloader nor the disk; any reset
#            lands back in the untouched NixOS boot entry
#   guard 1: the hardware watchdog is armed by systemd *before* the kexec
#            jump (KExecWatchdogSec on the NixOS side); if finix hangs
#            anywhere before the keepalive service runs, the board resets
#            into NixOS
#   guard 2: panic=30 / oops=panic / lockup panics turn kernel trouble
#            into a reboot into NixOS
#   guard 3: auto-return reboots into NixOS after the trial window unless
#            /persist/finix-trial/keep exists
#   guard 4: static IP fallback if DHCP fails, so SSH stays reachable
#   guard 5: boot breadcrumbs are persisted to /persist/finix-trial/ for
#            post-mortem from NixOS
#
# Remote diagnostics (headless boot debugging):
#   - netconsole is loaded from the initrd onward: all kernel messages are
#     streamed as UDP to the desktop (listen: nc -ulk 6666)
#   - initrd and stage-2 progress markers are echoed into /dev/kmsg, so
#     they ride the same netconsole stream
#
# /nix is mounted read-only: the trial physically cannot corrupt the
# NixOS store it is running from.
{
  config,
  lib,
  pkgs,
  ...
}: let
  diskUuid = "9dfc38c4-5c75-471d-9106-80ff9175ab92";
  # The server's LAN address (same as its NixOS DHCP lease; free during the
  # trial). Used as static fallback and as netconsole source.
  serverIp = "192.168.2.66";
  fallbackGateway = "192.168.2.1";
  # netconsole receiver: the desktop.
  netconsoleTarget = "192.168.2.28";
  netconsoleTargetMac = "58:11:22:b7:f0:29";
  netconsolePort = "6666";
  # Trial window before auto-return to NixOS. 30 min: enough to exercise
  # the ported services (forgejo/syncthing/tailscale/...); the 10-min
  # window was validated 3x before being raised.
  trialSeconds = 1800;

  netconsoleLoad = ''
    # The NIC driver is not loaded implicitly in the initrd (only the disk
    # path pulls modules in); load candidates explicitly so the interface
    # exists before netconsole tries to bind it.
    for m in r8169 igc e1000e; do
      modprobe "$m" 2>/dev/null || true
    done
    sleep 1

    # Interfaces can appear late or get renamed by the device manager;
    # retry against whatever actually exists.
    for _ in $(seq 1 30); do
      for path in /sys/class/net/*; do
        dev=$(basename "$path")
        [ "$dev" = lo ] && continue
        if modprobe netconsole "netconsole=+6665@${serverIp}/$dev,${netconsolePort}@${netconsoleTarget}/${netconsoleTargetMac}" 2>/dev/null; then
          echo "finix-diag: netconsole up on $dev" > /dev/kmsg || true
          exit 0
        fi
      done
      sleep 1
    done
    echo "finix-diag: netconsole failed on all interfaces" > /dev/kmsg || true
    exit 0
  '';

  kmsgDump = tag: cmds: ''
    {
      ${cmds}
    } 2>&1 | while IFS= read -r line; do
      echo "${tag}: $line" > /dev/kmsg || true
    done
  '';

  # finit spawns processes with no usable PATH: every script sets one
  # explicitly. A bare `sleep` that fails is how the trial spent hours
  # "crashing" at 13.5s (auto-return fell through to initctl reboot).
  watchdogKeepalive = pkgs.writeShellScript "watchdog-keepalive" ''
    set -u
    export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.kmod]}
    # The pre-kexec arming used whichever driver owns /dev/watchdog on
    # NixOS (intel_oc_wdt on this box). Load every candidate and pet every
    # watchdog device so the armed one is definitely covered.
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
        echo "watchdog-keepalive: petting $d (fd $fd)" > /dev/kmsg || true
      fi
    done

    if [ "''${#devs[@]}" -eq 0 ]; then
      echo "watchdog-keepalive: no watchdog devices found" >&2
      exit 1
    fi

    # Magic-close on clean shutdown so the reboot back into NixOS is not
    # racing a watchdog timeout.
    trap 'for fd in "''${devs[@]}"; do printf V >&"$fd"; done; exit 0' TERM INT
    while true; do
      for fd in "''${devs[@]}"; do
        printf '\0' >&"$fd"
      done
      sleep 5
    done
  '';

  netFallback = pkgs.writeShellScript "net-fallback" ''
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

    # Give dhcpcd a fair shot first.
    for _ in $(seq 1 45); do
      if ${pkgs.iproute2}/bin/ip -4 addr show scope global 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q 'inet '; then
        echo "net-fallback: dhcp succeeded, nothing to do"
        exit 0
      fi
      sleep 1
    done

    iface="$(find_iface)" || {
      echo "net-fallback: no ethernet interface found" >&2
      exit 1
    }

    echo "net-fallback: DHCP timed out, static ${serverIp}/24 on $iface"
    ${pkgs.iproute2}/bin/ip link set "$iface" up || true
    ${pkgs.iproute2}/bin/ip addr replace ${serverIp}/24 dev "$iface" || true
    ${pkgs.iproute2}/bin/ip route replace default via ${fallbackGateway} dev "$iface" || true
    printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf || true
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

    outdir=/persist/finix-trial
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

  autoReturn = pkgs.writeShellScript "auto-return" ''
    export PATH=${lib.makeBinPath [pkgs.coreutils]}
    # Fail SAFE: if sleep is broken we must NOT fall through to the reboot.
    sleep ${toString trialSeconds} || exit 1
    if [ -e /persist/finix-trial/keep ]; then
      echo "auto-return: keep marker present, staying on finix"
      exit 0
    fi
    echo "auto-return: trial window over, rebooting into NixOS" > /dev/kmsg || true
    exec ${config.finit.package}/bin/initctl reboot
  '';
in {
  networking.hostName = "finix-y0usaf-server";

  boot = {
    # Match the NixOS server's kernel exactly: 7.1.3 is proven to boot on
    # this box via kexec (kexec_selftest), while the nixpkgs default kernel
    # died before any console/netconsole output.
    kernelPackages = pkgs.linuxPackages_latest;

    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "sd_mod"
        "nvme"
        # NIC drivers: needed in the initrd for netconsole.
        "r8169"
        "igc"
        "e1000e"
        "netconsole"
      ];
      kernelModules = ["btrfs"];
      supportedFilesystems.btrfs.enable = true;

      # Remote eyes from the earliest possible moment.
      finit.tasks.netconsole = {
        description = "stream kernel log to desktop";
        script = netconsoleLoad;
      };

      # Progress markers ride the netconsole stream via /dev/kmsg.
      finit.tasks.initrd-diag = {
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
      "kvm-intel"
      # Single watchdog driver everywhere (matches the NixOS guard config):
      # a second watchdog device would be armed by our open() in the
      # keepalive and stay armed across the reboot back into NixOS.
      "intel_oc_wdt"
      "r8169"
      "igc"
      "e1000e"
    ];
    supportedFilesystems.btrfs.enable = true;
    # Guard 2: all kernel-level failures become a reboot into NixOS
    # (kexec consumed nothing; BootOrder still points at NixOS).
    kernelParams = [
      "console=tty0"
      "panic=30"
      "oops=panic"
      "softlockup_panic=1"
      "hung_task_panic=1"
    ];
  };

  # Belt & suspenders: keep coldplug from loading the second watchdog by
  # modalias. See kernelModules comment.
  environment.etc."modprobe.d/finix-trial-blacklist.conf".text = ''
    blacklist iTCO_wdt
    blacklist iTCO_vendor_support
  '';

  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = ["mode=755" "size=2G"];
    };

    # NOTE: no "ro" here! btrfs ro/rw is a superblock property on first
    # mount: an ro /nix makes the /persist rw mount (same fs) fail, which
    # kills stage 2 (fstab mount task fails -> finit reboots). The store is
    # still protected by finix's built-in remount-nix-store ro bind.
    "/nix" = {
      device = "/dev/disk/by-uuid/${diskUuid}";
      fsType = "btrfs";
      options = ["subvol=@nix" "noatime"];
      neededForBoot = true;
    };

    # neededForBoot is required for the mount to happen AT ALL: finix's
    # finit/mount.nix only generates mount tasks for neededForBoot
    # filesystems; everything else is written to /etc/fstab and then never
    # mounted. TODO: report upstream.
    "/persist" = {
      device = "/dev/disk/by-uuid/${diskUuid}";
      fsType = "btrfs";
      options = ["subvol=@persist" "compress=zstd" "noatime"];
      neededForBoot = true;
    };
  };

  services.getty = {
    enable = true;
    ttys = ["tty1" "ttyS0"];
  };

  # Guard 1: take over watchdog petting from the pre-kexec arming.
  # No conditions: this must start as early as possible.
  finit.services.watchdog-keepalive = {
    description = "trial watchdog keepalive";
    command = "${watchdogKeepalive}";
    log = true;
  };

  # Stage-2 netconsole retry (no-op if the initrd already loaded it) and
  # a status dump that rides the netconsole stream.
  finit.tasks.netconsole-retry = {
    description = "ensure netconsole is loaded";
    command = pkgs.writeShellScript "netconsole-retry" netconsoleLoad;
    path = [pkgs.kmod pkgs.coreutils];
    log = true;
  };

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
  # /persist. Supervised service, not a backgrounded run task: finit reaps
  # the task's cgroup on exit, which silently killed earlier attempts.
  # commit=1 keeps the log durable without an explicit sync loop.
  finit.services.kmsg-recorder = {
    description = "kmsg flight recorder to /persist";
    log = true;
    command = pkgs.writeShellScript "kmsg-recorder" ''
      export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.util-linux]}
      # Self-sufficient: mount the persist subvolume ourselves instead of
      # depending on fstab handling that may not have happened yet.
      mnt=/run/kmsg-persist
      mkdir -p "$mnt"
      until mountpoint -q "$mnt"; do
        for dev in /dev/disk/by-uuid/${diskUuid} /dev/sda2 /dev/nvme0n1p2; do
          [ -b "$dev" ] || continue
          mount -t btrfs -o subvol=@persist,commit=1 "$dev" "$mnt" 2>/dev/null && break 2
        done
        sleep 1
      done
      d="$mnt/finix-trial"
      mkdir -p "$d"
      ts=$(date -u +%Y-%m-%dT%H-%M-%SZ)
      echo "kmsg-recorder: writing to $d/kmsg-$ts.log" > /dev/kmsg
      # /dev/kmsg replays the entire buffer from boot, then follows.
      exec cat /dev/kmsg > "$d/kmsg-$ts.log"
    '';
  };

  # Guard 4: keep SSH reachable even if DHCP is broken.
  finit.tasks.net-fallback = {
    description = "static IP fallback if DHCP fails";
    command = "${netFallback}";
    conditions = ["net/lo/up"];
    log = true;
  };

  # Guard 5: persist post-mortem data where NixOS can read it.
  # Unconditional: even a partial boot should leave traces.
  finit.tasks.boot-breadcrumb = {
    description = "persist boot breadcrumbs";
    command = "${breadcrumb}";
    log = true;
  };

  # Guard 3: bounded trial window unless explicitly kept. A task, not a
  # service: it must run exactly once and not be restarted on exit.
  finit.tasks.auto-return = {
    description = "auto return to NixOS after trial window";
    command = "${autoReturn}";
    log = true;
  };
}
