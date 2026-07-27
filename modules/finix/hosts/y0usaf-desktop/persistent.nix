# Phase-1 finix skeleton for y0usaf-desktop: console boot, network, sshd,
# nix-daemon, and the FULL NixOS impermanence semantics (tmpfs root, data
# subvols, /persist allowlist replayed as bind mounts). No graphical
# session yet — that is phase 2 (seatd/dbus/niri/pipewire).
#
# Boot model (2026-07-27+): finix IS the installed OS on this box and owns
# /boot via the upstream programs.limine module (./boot.nix) — the Limine
# menu lists finix generations, the NixOS rescue entries are gone, Windows
# boots via its own EFI entry. Day-2 driver: nh os switch (build → activate
# → profile generation → boot-menu render). The server is unchanged (ESP
# island, headless deadman). See modules/finix/NOTES.md.
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

  # Single source of truth: the NixOS impermanence module for this host is a
  # pure-literal function — call it and replay the same allowlist here.
  persistCfg =
    ((import ../../../../hosts/y0usaf-desktop/impermanence.nix) {})
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
  # Deliberate, reversible exit to the rescue OS (one-shot; BootOrder kept).
in {
  imports = [./boot.nix ./graphical.nix ./session.nix ./packages-bridge.nix ./audio.nix ./parity.nix ./dotfiles.nix];

  networking.hostName = "y0usaf-desktop";
  # No MagicDNS parity yet (tailscaled runs, resolv.conf is static): pin the
  # tailnet names ssh config + git remotes rely on (forgejo = y0usaf-server).
  networking.hosts."100.105.204.116" = ["y0usaf-server"];

  finix.diagnostics = {
    enable = true;
    inherit diskUuid;
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
  environment = {
    etc."modprobe.d/finix-desktop-blacklist.conf".text = ''
      blacklist nouveau
    '';
    etc."finix-stage2".text = "desktop-phase2.4\n";
    # Bare `nh os switch` targets this repo (nh resolves the hostname-keyed
    # nixosConfigurations.y0usaf-desktop = this finix system).
    etc."profile.d/nh.sh".text = ''
      export NH_FLAKE=/home/y0usaf/nixos
    '';
    systemPackages = [
      pkgs.nix
      pkgs.efibootmgr
      # Server cockpit + local runtime-only trial. Local switch/boot are
      # GONE: `nh os switch` is the local driver — upstream programs.limine
      # (./boot.nix) made switch-to-configuration self-contained: activate +
      # profile generation + Limine menu render. Dispatch-only via nix run,
      # so this never goes stale inside the system closure.
      (pkgs.writeShellScriptBin "fx" ''
        set -euo pipefail
        flake="''${FX_FLAKE:-/home/y0usaf/nixos}"
        case "''${1:-}" in
          test)
            # runtime-only activation; never touches the boot menu
            exec nix run "$flake#finix-desktop-deploy" -- local test ;;
          server)
            shift; sv="''${1:?usage: fx server <verb>}"
            case "$sv" in
              switch|test|boot) exec nix run "$flake#finix-server-persistent-deploy" -- server "$sv" ;;
              *) exec nix run "$flake#finix-server-boot" -- server "$sv" ;;
            esac ;;
          *)
            echo "this machine: nh os switch — fx only keeps:" >&2
            echo "  fx test                     runtime-only activation trial" >&2
            echo "  fx server switch|test|install|oneshot|promote|demote|rollback|status" >&2
            exit 2 ;;
        esac
      '')
      pkgs.git
      pkgs.curl
      pkgs.iproute2
      pkgs.iputils
      pkgs.procps
      pkgs.util-linux
      pkgs.vim
      # Daily driver essentials until the real package set lands (phase 2):
      flakeInputs.pi-flake.packages."${pkgs.stdenv.hostPlatform.system}".pi
      # nh is the day-2 driver now (./boot.nix made switch-to-configuration
      # self-contained); NH_FLAKE above points bare `nh os switch` here.
      flakeInputs.nh.packages."${pkgs.stdenv.hostPlatform.system}".default
    ];
  };

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
      # Unattended self-heal: any panic reboots after 30s into Limine's
      # default — finix itself since 2026-07-27 (single-Limine era; was the
      # NixOS BootOrder head in the island trial era).
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
        value =
          (dir: {
            device = "/persist${dir}";
            # finix's initrd generator requires a real fsType for neededForBoot binds;
            # mount.nix ignores it when the bind option is present.
            fsType = "btrfs";
            options = ["bind"];
            neededForBoot = true;
          })
          d;
      })
      (builtins.filter (d: !lib.hasPrefix "/etc/" d && d != "/root")
        (map dirPath persistCfg.directories)));

  services = {
    getty = {
      enable = true;
      ttys = ["tty1" "tty2"];
    };
    openssh.settings = {
      # Parity with the NixOS universe: real sshd on 2222; :22 stays free
      # for Tailscale SSH once tailscaled lands (phase 2).
      Port = [2222];
      # Reuse the NixOS host key from /persist/etc/ssh: same host identity
      # under either OS, no known_hosts churn. ed25519 only — finix renders
      # list settings space-joined on ONE line (upstream gotcha).
      HostKey = lib.mkForce ["/persist/etc/ssh/ssh_host_ed25519_key"];
      AuthorizedKeysFile = lib.mkForce ["/persist/etc/ssh/authorized_keys.d/%u"];
      UsePAM = lib.mkForce true;
      StrictModes = lib.mkForce true;
    };
    nix-daemon = {
      enable = true;
      settings = {
        trusted-users = ["root" "y0usaf"];
        # Phase-2a lesson: every nix invocation needed --extra-experimental-features.
        experimental-features = ["nix-command" "flakes"];
      };
    };
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

  # Upstream task generates a throwaway key in /var/lib/sshd; sshd's start
  # would race it. The persisted key must already exist — assert, not create.
  finit = {
    tasks = {
      ssh-keygen.command = lib.mkForce (pkgs.writeShellScript "check-host-keys" ''
        [ -s /persist/etc/ssh/ssh_host_ed25519_key ]
      '');
      net-fallback = {
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
          ${pkgs.iproute2}/bin/ip addr replace 192.168.2.28/24 dev "$iface" || true
          ${pkgs.iproute2}/bin/ip route replace default via 192.168.2.1 dev "$iface" || true
          printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf || true
        ''}";
        conditions = ["net/lo/up"];
        log = true;
      };
      persist-user-binds = {
        description = "replay the impermanence user allowlist as bind mounts";
        command = "${pkgs.writeShellScript "persist-user-binds" ''
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
          done < ${pkgs.writeText "persist-user-binds" (lib.concatMapStrings (d: "${d}\n") (map dirPath persistCfg.users.y0usaf.directories))}

          while IFS= read -r rel; do
            [ -n "$rel" ] || continue
            src="$src_root/$rel"
            dst="$dst_root/$rel"
            [ -f "$src" ] || { install -o y0usaf -g users -m 0600 /dev/null "$src" || { fail=1; continue; }; }
            [ -f "$dst" ] || { install -o y0usaf -g users -m 0600 /dev/null "$dst" || { fail=1; continue; }; }
            mountpoint -q "$dst" || mount --bind "$src" "$dst" || fail=1
          done < ${pkgs.writeText "persist-user-files" (lib.concatMapStrings (f: "${f}\n") userFiles)}

          [ "$fail" = 0 ] || { echo "persist-user-binds: some binds failed" >&2; exit 1; }
          echo "persist-user-binds: allowlist mounted"
        ''}";
        log = true;
      };
      remount-nix-store.enable = false;
    };
  };

  # The desktop must accept pushed closures + local rebuilds.

  # Console-visible generation marker + deploy-path prover.
}
