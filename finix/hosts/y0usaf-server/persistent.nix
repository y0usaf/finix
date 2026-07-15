# Stage-2 persistent Finix system for y0usaf-server.
#
# This is the trial system without the bounded trial machinery: the root stays
# ephemeral, durable state remains on the existing @persist/@home subvolumes,
# and the machine no longer returns to NixOS on a timer. NixOS remains the
# bootloader/rescue system until the Limine takeover in stage 3.
{
  config,
  lib,
  pkgs,
  ...
}: let
  diskUuid = "9dfc38c4-5c75-471d-9106-80ff9175ab92";
  serverIp = "192.168.2.66";
  fallbackGateway = "192.168.2.1";

  watchdogKeepalive = pkgs.writeShellScript "persistent-watchdog-keepalive" ''
    set -u
    export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.kmod]}

    # Keep the same single watchdog driver used by both NixOS and the trial.
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

    # Magic-close on a clean shutdown; otherwise an armed watchdog covers
    # hangs during a kexec/reboot and keeps the NixOS rescue path viable.
    trap 'for fd in "''${devs[@]}"; do printf V >&"$fd"; done; exit 0' TERM INT
    while true; do
      for fd in "''${devs[@]}"; do
        printf '\0' >&"$fd"
      done
      sleep 5
    done
  '';

  netFallback = pkgs.writeShellScript "persistent-net-fallback" ''
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

    # DHCP is authoritative; only install the known-good static fallback after
    # a fair wait so a delayed lease is never needlessly replaced.
    for _ in $(seq 1 45); do
      if ${pkgs.iproute2}/bin/ip -4 addr show scope global 2>/dev/null \
        | ${pkgs.gnugrep}/bin/grep -q 'inet '; then
        exit 0
      fi
      sleep 1
    done

    iface="$(find_iface)" || exit 1
    ${pkgs.iproute2}/bin/ip link set "$iface" up || true
    ${pkgs.iproute2}/bin/ip addr replace ${serverIp}/24 dev "$iface" || true
    ${pkgs.iproute2}/bin/ip route replace default via ${fallbackGateway} dev "$iface" || true
    printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf || true
  '';

  # Boot diagnostics, ported from the trial config after the 2026-07-15
  # warm-reboot hang left zero logs (died before syslog/binds). Markers
  # echoed into /dev/kmsg are replayed by the flight recorder once it
  # starts, so initrd/stage-2 progress survives in /persist even when
  # syslog never came up. Log home: /persist/finix-boot/ (finix-trial/
  # stays trial-only).
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

    outdir=/persist/finix-boot
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

  # Arm-first dead-man switch for the stage-3 era: point BootNext at the
  # NixOS loader as early as possible, clear it only once this boot proves
  # healthy. Any crash/hang/watchdog reset before that lands the next
  # firmware boot in NixOS, where the box parks (NixOS never auto-reboots).
  # Harmless during the kexec era: NixOS is the bootloader default anyway.
  bootnextDeadman = pkgs.writeShellScript "persistent-bootnext-deadman" ''
    set -u
    export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.util-linux pkgs.efibootmgr pkgs.gnugrep pkgs.gnused pkgs.iproute2]}

    mountpoint -q /sys/firmware/efi/efivars \
      || mount -t efivarfs efivarfs /sys/firmware/efi/efivars \
      || { echo "bootnext-deadman: no efivars; not armed" >&2; exit 1; }

    lim="$(efibootmgr | sed -n 's/^Boot\([0-9A-F]\{4\}\)[^ ]* Limine\t.*/\1/p' | head -n1)"
    if [ -z "$lim" ]; then
      echo "bootnext-deadman: no Limine EFI entry; not armed" >&2
      exit 1
    fi
    efibootmgr -q -n "$lim" || { echo "bootnext-deadman: arming failed" >&2; exit 1; }
    echo "bootnext-deadman: armed BootNext=Boot$lim (NixOS)"

    # Healthy = sshd continuously listening for 2 minutes (10-minute budget).
    ok=0
    for _ in $(seq 1 60); do
      if ss -ltn 2>/dev/null | grep -q ':22 '; then
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
    echo "bootnext-deadman: health timeout; BootNext stays armed (next boot = NixOS)" >&2
    exit 1
  '';

  # Deliberate, reversible exit to the rescue OS: survives promotion of the
  # Finix island to BootOrder head (one-shot, does not touch BootOrder).
  bootNixos = pkgs.writeShellScriptBin "boot-nixos" ''
    set -eu
    export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.util-linux pkgs.efibootmgr pkgs.gnused]}
    [ "$(id -u)" = 0 ] || { echo "boot-nixos: run with sudo" >&2; exit 1; }
    mountpoint -q /sys/firmware/efi/efivars \
      || mount -t efivarfs efivarfs /sys/firmware/efi/efivars
    lim="$(efibootmgr | sed -n 's/^Boot\([0-9A-F]\{4\}\)[^ ]* Limine\t.*/\1/p' | head -n1)"
    [ -n "$lim" ] || { echo "boot-nixos: no Limine EFI entry" >&2; exit 1; }
    efibootmgr -q -n "$lim"
    echo "boot-nixos: BootNext=Boot$lim; rebooting into NixOS rescue"
    exec /run/current-system/sw/bin/initctl reboot
  '';

  bindMount = dir: {
    device = "/persist${dir}";
    # finix's initrd generator requires a real fsType for neededForBoot binds;
    # mount.nix ignores it when the bind option is present.
    fsType = "btrfs";
    options = ["bind"];
    neededForBoot = true;
  };
in {
  networking.hostName = "y0usaf-server";

  boot = {
    # Same proven kernel as the NixOS host and the metal trial.
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
      kernelModules = ["btrfs"];
      supportedFilesystems.btrfs.enable = true;

      # Progress markers into /dev/kmsg: visible on the console during a
      # pre-userspace hang and replayed into the flight recorder log on a
      # healthy boot. (No netconsole/beacon here by design — trial-only.)
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
      "intel_oc_wdt"
      "r8169"
      "igc"
      "e1000e"
    ];
    supportedFilesystems = {
      btrfs.enable = true;
      # BootNext dead-man switch + boot-nixos need EFI variables; the scripts
      # mount efivarfs themselves, this just guarantees kernel support.
      efivarfs.enable = true;
    };
    kernelParams = [
      "console=tty0"
      "panic=30"
      "oops=panic"
      "softlockup_panic=1"
      "hung_task_panic=1"
    ];
  };

  environment.etc."modprobe.d/finix-server-blacklist.conf".text = ''
    blacklist iTCO_wdt
    blacklist iTCO_vendor_support
  '';

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

    # ESP, shared with NixOS. The island tooling (finix-esp-island) and any
    # kernel/initrd slot updates run from finix after the takeover, so the
    # ESP must be reachable here too. neededForBoot: mount.nix only creates
    # mount tasks for neededForBoot filesystems (upstream gotcha #1).
    "/boot" = {
      device = "/dev/disk/by-uuid/41B0-E342";
      fsType = "vfat";
      options = ["umask=0077" "noatime"];
      neededForBoot = true;
    };

    "/var/log" = bindMount "/var/log";
  };

  services.getty = {
    enable = true;
    ttys = ["tty1" "ttyS0"];
  };

  # /persist is mounted before activation, so userborn can consume the same
  # password hash as NixOS rather than embedding the trial-only password.
  users.users.y0usaf = {
    password = lib.mkForce null;
    passwordFile = lib.mkForce "/persist/secrets/password-hashes/y0usaf";
  };

  # environment.etc files are store-backed symlinks; StrictModes rejects the
  # /nix/store ancestor. Copy the generated keys to the durable filesystem so
  # SSH can keep StrictModes and PAM enabled with the persisted shadow state.
  system.activation.scripts.persistentSshAuthorizedKeys = {
    deps = ["etc"];
    text = ''
      ${pkgs.coreutils}/bin/install -d -m 0755 /persist/etc/ssh/authorized_keys.d
      ${pkgs.coreutils}/bin/install -m 0644 -o root -g root \
        /etc/ssh/authorized_keys.d/y0usaf \
        /persist/etc/ssh/authorized_keys.d/y0usaf
    '';
  };

  services.openssh.settings = {
    AuthorizedKeysFile = lib.mkForce ["/persist/etc/ssh/authorized_keys.d/%u"];
    UsePAM = lib.mkForce true;
    StrictModes = lib.mkForce true;
  };

  finit.services.watchdog-keepalive = {
    description = "persistent watchdog keepalive";
    command = "${watchdogKeepalive}";
    log = true;
  };

  finit.tasks.net-fallback = {
    description = "static IP fallback if DHCP fails";
    command = "${netFallback}";
    conditions = ["net/lo/up"];
    log = true;
  };

  finit.tasks.bootnext-deadman = {
    description = "EFI BootNext dead-man switch (fall home to NixOS)";
    command = "${bootnextDeadman}";
    log = true;
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
  # /persist. Supervised service, not a backgrounded run task: finit reaps
  # a run task's cgroup on exit, which silently killed earlier attempts.
  # commit=1 keeps the log durable without an explicit sync loop.
  finit.services.kmsg-recorder = {
    description = "kmsg flight recorder to /persist";
    log = true;
    command = pkgs.writeShellScript "kmsg-recorder" ''
      export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.util-linux pkgs.findutils]}
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
      d="$mnt/finix-boot"
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

  # The persistent machine must accept pushed closures; unlike the guarded
  # trial, leave /nix/store writable for the Nix daemon.
  finit.tasks.remount-nix-store.enable = false;

  services.nix-daemon = {
    enable = true;
    settings.trusted-users = ["root" "y0usaf"];
  };

  # Small activation marker used to prove the SSH deployment path without a
  # reboot; it also makes the active generation obvious from the console.
  environment.etc."finix-stage2".text = "persistent\n";
  # Keep the Nix client in the closure for SSH-based deployments. The daemon
  # is used as the remote store endpoint; local builds remain optional.
  # efibootmgr backs the ESP-island tooling, the dead-man switch, and manual
  # BootNext surgery; boot-nixos is the always-available exit to the rescue OS.
  environment.systemPackages = [pkgs.nix pkgs.efibootmgr bootNixos];
}
