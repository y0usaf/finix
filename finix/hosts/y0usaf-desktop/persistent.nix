# Phase-1 finix skeleton for y0usaf-desktop: console boot, network, sshd,
# nix-daemon, and the FULL NixOS impermanence semantics (tmpfs root, data
# subvols, /persist allowlist replayed as bind mounts). No graphical
# session yet — that is phase 2 (seatd/dbus/niri/pipewire).
#
# Dual-boot model (same as the server): NixOS keeps /boot/limine and stays
# the BootOrder head; this system boots via the self-contained ESP island
# (\EFI\finix\) one-shot at a time until it earns promote. Windows entry
# untouched. See finix/NOTES.md.
#
# Deliberately NOT here yet (phase 2+): NVIDIA, seat/session stack, zram
# (no upstream module), /swap subvol (unused; swapDevices=[] on NixOS too),
# NetworkManager (dhcpcd on eno1/igc covers a wired desktop), bluetooth,
# docker, tailscale, @home-blank rollback (NixOS rolls @home back on ITS
# next boot; allowlisted writes land in /persist either way — identical
# durability semantics, just deferred cleanup of @home noise).
{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  diskUuid = "32ad19b5-88df-4e63-92d2-d5a150ad65c5";
  desktopIp = "192.168.2.28";
  fallbackGateway = "192.168.2.1";

  # Single source of truth: the NixOS impermanence module for this host is a
  # pure-literal function — call it and replay the same allowlist here.
  persistCfg =
    ((import ../../../hosts/y0usaf-desktop/impermanence.nix) {})
    .environment
    .persistence
    ."/persist";
  dirPath = e:
    if builtins.isAttrs e
    then e.directory
    else e;
  # /etc/* entries are NOT bind-mounted under finix: /etc is finix-managed
  # (a bind would shadow generated config, e.g. sshd_config). ssh host keys
  # are consumed in place from /persist/etc/ssh; machine-id is copied by an
  # activation script below. "/root" is bound by the persist-binds task:
  # upstream escapePath maps both "/" and "/root" to the finit stanza name
  # "root", so it cannot be a neededForBoot fstab entry (collision assert).
  # Everything else (/var/*) binds 1:1 via fstab.
  systemBindDirs =
    builtins.filter (d: !lib.hasPrefix "/etc/" d && d != "/root")
    (map dirPath persistCfg.directories);
  userDirs = map dirPath persistCfg.users.y0usaf.directories;
  userFiles = persistCfg.users.y0usaf.files;

  btrfsOpts = ["compress=zstd:3" "noatime" "ssd" "space_cache=v2"];
  subvolMount = name: extraOpts: {
    device = "/dev/disk/by-uuid/${diskUuid}";
    fsType = "btrfs";
    options = ["subvol=${name}"] ++ btrfsOpts ++ extraOpts;
  };

  # The 250-entry user allowlist as one supervised task instead of 250 fstab
  # mount tasks: same bind-mount semantics as the impermanence module,
  # ownership applied only to directories this script itself creates.
  userBindList = pkgs.writeText "persist-user-binds" (lib.concatMapStrings (d: "${d}\n") userDirs);
  userFileList = pkgs.writeText "persist-user-files" (lib.concatMapStrings (f: "${f}\n") userFiles);
  persistUserBinds = pkgs.writeShellScript "persist-user-binds" ''
    set -u
    export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.util-linux]}

    for _ in $(seq 1 120); do
      mountpoint -q /persist && mountpoint -q /home && break
      sleep 1
    done
    mountpoint -q /persist || { echo "persist-user-binds: /persist never mounted" >&2; exit 1; }
    mountpoint -q /home || { echo "persist-user-binds: /home never mounted" >&2; exit 1; }

    fail=0

    # /root first: kept out of fstab (escapePath collision with "/", see
    # systemBindDirs above). Root-owned, mode from the allowlist (0700).
    install -d -m 0700 /persist/root
    install -d -m 0700 /root
    mountpoint -q /root || mount --bind /persist/root /root || fail=1

    src_root=/persist/home/y0usaf
    dst_root=/home/y0usaf

    while IFS= read -r rel; do
      [ -n "$rel" ] || continue
      src="$src_root/$rel"
      dst="$dst_root/$rel"
      [ -d "$src" ] || install -d -o y0usaf -g users "$src" || { fail=1; continue; }
      [ -d "$dst" ] || install -d -o y0usaf -g users "$dst" || { fail=1; continue; }
      mountpoint -q "$dst" || mount --bind "$src" "$dst" || fail=1
    done < ${userBindList}

    while IFS= read -r rel; do
      [ -n "$rel" ] || continue
      src="$src_root/$rel"
      dst="$dst_root/$rel"
      [ -f "$src" ] || { install -o y0usaf -g users -m 0600 /dev/null "$src" || { fail=1; continue; }; }
      [ -f "$dst" ] || { install -o y0usaf -g users -m 0600 /dev/null "$dst" || { fail=1; continue; }; }
      mountpoint -q "$dst" || mount --bind "$src" "$dst" || fail=1
    done < ${userFileList}

    [ "$fail" = 0 ] || { echo "persist-user-binds: some binds failed" >&2; exit 1; }
    echo "persist-user-binds: allowlist mounted"
  '';

  netFallback = pkgs.writeShellScript "desktop-net-fallback" ''
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
    ${pkgs.iproute2}/bin/ip addr replace ${desktopIp}/24 dev "$iface" || true
    ${pkgs.iproute2}/bin/ip route replace default via ${fallbackGateway} dev "$iface" || true
    printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf || true
  '';

  # Deliberate, reversible exit to the rescue OS (one-shot; BootOrder kept).
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

  # Arm-first dead-man switch, ported from the server: point BootNext at the
  # NixOS loader as early as possible, clear it only once this boot proves
  # healthy. Any crash/hang before that lands the next firmware boot in
  # NixOS. Pre-promote this just mirrors BootOrder (harmless); post-promote
  # it is THE guard against a bad slot parking the box on a broken boot.
  bootnextDeadman = pkgs.writeShellScript "desktop-bootnext-deadman" ''
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

  bindMount = dir: {
    device = "/persist${dir}";
    # finix's initrd generator requires a real fsType for neededForBoot binds;
    # mount.nix ignores it when the bind option is present.
    fsType = "btrfs";
    options = ["bind"];
    neededForBoot = true;
  };
in {
  imports = [./graphical.nix ./session.nix ./packages-bridge.nix ./audio.nix ./parity.nix];

  networking.hostName = "y0usaf-desktop";

  finix.diagnostics = {
    enable = true;
    diskUuid = diskUuid;
    fallbackDevices = ["/dev/nvme0n1p5"];
  };

  # amdgpu (Ryzen iGPU drives the console) pulls firmware blobs at modeset;
  # first boot logged psp/dcn/gc load failures and fell back to efifb.
  hardware.firmware = [pkgs.linux-firmware];

  # nouveau: the monitor hangs off the NVIDIA dGPU; nouveau's GSP DP-AUX
  # retry loop (ctrl cmd 0x00731341 failed / DP-4 invalid native reply)
  # strobes the display on/off every ~6ms — see kmsg-2026-07-17T12-05-12Z.
  # NixOS blacklists nouveau too (proprietary driver); phase 2 brings the
  # real NVIDIA stack. Without nouveau the dGPU-connected console stays on
  # simpledrm (boot-1 behavior, stable).
  environment.etc."modprobe.d/finix-desktop-blacklist.conf".text = ''
    blacklist nouveau
  '';

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    extraModulePackages = [config.boot.kernelPackages.zenpower];
    initrd = {
      availableKernelModules = [
        "nvme"
        "thunderbolt"
        "xhci_pci"
        "ahci"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
      kernelModules = ["btrfs"];
      supportedFilesystems.btrfs.enable = true;
    };
    kernelModules = [
      "kvm-amd"
      "k10temp"
      "nct6775"
      "zenpower"
      "igc" # eno1; net-fallback needs the NIC even if dhcpcd never ran
    ];
    supportedFilesystems = {
      btrfs.enable = true;
      # boot-nixos + the island tooling touch EFI variables; the scripts
      # mount efivarfs themselves, this guarantees kernel support.
      efivarfs.enable = true;
    };
    kernelParams = [
      "amd_pstate=active"
      "mitigations=off"
      "console=tty0"
      # Unattended fall-home for oneshot trials: any panic reboots into the
      # BootOrder head (NixOS) after 30s.
      "panic=30"
      "oops=panic"
      "softlockup_panic=1"
      "hung_task_panic=1"
    ];
  };

  fileSystems =
    {
      "/" = {
        device = "none";
        fsType = "tmpfs";
        options = ["mode=755" "size=4G"];
      };

      "/nix" = subvolMount "@nix" [] // {neededForBoot = true;};
      "/persist" = subvolMount "@persist" [] // {neededForBoot = true;};
      "/home" = subvolMount "@home" [] // {neededForBoot = true;};

      "/btrfs" = {
        device = "/dev/disk/by-uuid/${diskUuid}";
        fsType = "btrfs";
        options = ["subvolid=5"] ++ btrfsOpts;
        neededForBoot = true;
      };

      # ESP, shared with NixOS (and Windows). Island slot updates run from
      # here after the takeover. neededForBoot: mount.nix only creates mount
      # tasks for neededForBoot filesystems (upstream gotcha #1).
      "/boot" = {
        device = "/dev/disk/by-uuid/31F2-1AE7";
        fsType = "vfat";
        options = ["fmask=0077" "dmask=0077" "noatime"];
        neededForBoot = true;
      };

      # Durable bulk data on dedicated subvols, exactly as under NixOS.
      "/home/y0usaf/old-home" = subvolMount "@home-old" ["ro"] // {neededForBoot = true;};
      "/home/y0usaf/.local/share/Steam" = subvolMount "@steam" [] // {neededForBoot = true;};
      "/home/y0usaf/Pictures" = subvolMount "@pictures" [] // {neededForBoot = true;};
      "/home/y0usaf/DCIM" = subvolMount "@dcim" [] // {neededForBoot = true;};
      "/home/y0usaf/Music" = subvolMount "@music" [] // {neededForBoot = true;};
    }
    # System allowlist (/var/lib/*, /var/log, /root) as fstab binds: mounted
    # early, before activation and services.
    // builtins.listToAttrs (map (d: {
        name = d;
        value = bindMount d;
      })
      systemBindDirs);

  services.getty = {
    enable = true;
    ttys = ["tty1" "tty2"];
  };

  # Same credentials as the NixOS install (impermanence keeps these paths).
  # uid PINNED to the NixOS value: this box's y0usaf is 1001 (not the 1000
  # finix would auto-allocate). First finix boot ran as 1000 and every
  # /persist + @home file (owned 1001) was foreign — libgit2 refused repos,
  # tools broke. Keep in lockstep with `id y0usaf` under NixOS forever.
  users.users.y0usaf = {
    uid = 1001;
    password = lib.mkForce null;
    passwordFile = lib.mkForce "/persist/secrets/password-hashes/y0usaf";
  };
  users.users.root.passwordFile = "/persist/secrets/password-hashes/root";

  # environment.etc files are store-backed symlinks; StrictModes rejects the
  # /nix/store ancestor. Copy the generated keys to the durable filesystem so
  # SSH keeps StrictModes and PAM enabled against the persisted shadow state.
  system.activation.scripts.persistentSshAuthorizedKeys = {
    deps = ["etc"];
    text = ''
      ${pkgs.coreutils}/bin/install -d -m 0755 /persist/etc/ssh/authorized_keys.d
      ${pkgs.coreutils}/bin/install -m 0644 -o root -g root \
        /etc/ssh/authorized_keys.d/y0usaf \
        /persist/etc/ssh/authorized_keys.d/y0usaf
    '';
  };

  # machine-id: NixOS persists it via a bind; here /etc is finix-managed, so
  # copy the persisted identity into place before dbus (phase 2) wants it.
  system.activation.scripts.persistentMachineId.text = ''
    if [ -s /persist/etc/machine-id ]; then
      ${pkgs.coreutils}/bin/install -m 0444 /persist/etc/machine-id /etc/machine-id
    fi
  '';

  services.openssh.settings = {
    # Reuse the NixOS host key from /persist/etc/ssh: same host identity
    # under either OS, no known_hosts churn. ed25519 only — finix renders
    # list settings space-joined on ONE line (upstream gotcha).
    HostKey = lib.mkForce ["/persist/etc/ssh/ssh_host_ed25519_key"];
    AuthorizedKeysFile = lib.mkForce ["/persist/etc/ssh/authorized_keys.d/%u"];
    UsePAM = lib.mkForce true;
    StrictModes = lib.mkForce true;
  };

  # Upstream task generates a throwaway key in /var/lib/sshd; sshd's start
  # would race it. The persisted key must already exist — assert, not create.
  finit.tasks.ssh-keygen.command = lib.mkForce (pkgs.writeShellScript "check-host-keys" ''
    [ -s /persist/etc/ssh/ssh_host_ed25519_key ]
  '');

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

  finit.tasks.persist-user-binds = {
    description = "replay the impermanence user allowlist as bind mounts";
    command = "${persistUserBinds}";
    log = true;
  };

  # The desktop must accept pushed closures + local rebuilds.
  finit.tasks.remount-nix-store.enable = false;

  services.nix-daemon = {
    enable = true;
    settings = {
      trusted-users = ["root" "y0usaf"];
      # Phase-2a lesson: every nix invocation needed --extra-experimental-features.
      experimental-features = ["nix-command" "flakes"];
    };
  };

  # Console-visible generation marker + deploy-path prover.
  environment.etc."finix-stage2".text = "desktop-phase2.6\n";

  environment.systemPackages = [
    pkgs.nix
    pkgs.efibootmgr
    bootNixos
    pkgs.git
    pkgs.curl
    pkgs.iproute2
    pkgs.iputils
    pkgs.procps
    pkgs.util-linux
    pkgs.vim
    # Daily driver essentials until the real package set lands (phase 2):
    flakeInputs.pi-flake.packages.${pkgs.stdenv.hostPlatform.system}.pi
  ];
}
