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
# island, headless deadman). See finix/NOTES.md.
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

  # Common btrfs mount options, matching the NixOS hardware-configuration.nix.
  btrfsOpts = ["compress=zstd:3" "noatime" "ssd" "space_cache=v2"];
  # Helper: build a btrfs subvol mount attrset from subvol name + extra opts.
  # Extra opts are appended after the standard btrfs options (e.g. ["ro"]).
  subvolMount = subvol: extraOpts: {
    device = "/dev/disk/by-uuid/${diskUuid}";
    fsType = "btrfs";
    options = ["subvol=${subvol}"] ++ btrfsOpts ++ extraOpts;
  };

  # Single source of truth: pass finix's evaluated config into the NixOS
  # impermanence data function so enable-gated app paths match this system.
  persistCfg =
    ((import ../impermanence.nix) {inherit config;})
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

  # btrfs snapshot-reset ("wipe on boot") helpers. homeTemplateDirs is the
  # set of intermediate ancestor dirs that must exist (y0usaf-owned) inside
  # the @home-blank skeleton so the allowlist binds land on cleanly-owned
  # parents: for each allowlist DIRECTORY entry, every proper ancestor
  # ("a/b/c" -> "a", "a/b"); for each allowlist FILE entry, its dirname plus
  # every proper ancestor of that dirname. Computed here at eval time so the
  # template can never drift from the allowlist; the leaf dirs/files
  # themselves are created by persist-user-binds, not baked into the template.
  splitPath = p: builtins.filter (s: s != "") (lib.splitString "/" p);
  properAncestors = p: let
    parts = splitPath p;
  in
    lib.init (lib.genList (i: lib.concatStringsSep "/" (lib.take (i + 1) parts)) (lib.length parts));
  dirnameOf = p: let
    parts = splitPath p;
  in
    lib.optional (lib.length parts > 1) (lib.concatStringsSep "/" (lib.init parts));
  fileTemplateDirs = builtins.concatMap (f: let
    d = dirnameOf (dirPath f);
  in
    d ++ lib.concatMap properAncestors d)
  userFiles;
  dirTemplateDirs = builtins.concatMap (d: properAncestors (dirPath d)) persistCfg.users.y0usaf.directories;
  homeTemplateDirs = lib.unique (dirTemplateDirs ++ fileTemplateDirs);

  # The dedicated data-subvol mounts under the home dir (old-home, Steam,
  # dev, Pictures, DCIM, Music): derived from the fstab set so the skeleton
  # follows the mounts, then each mountpoint's path relative to /home/y0usaf.
  dataSubvolMounts =
    lib.unique (map (mp: lib.removePrefix "/home/y0usaf/" mp)
      (builtins.filter (mp: lib.hasPrefix "/home/y0usaf/" mp) (builtins.attrNames config.fileSystems)));
  # The 250-entry user allowlist as one supervised task instead of 250 fstab
  # mount tasks: same bind-mount semantics as the impermanence module,
  # ownership applied only to directories this script itself creates.
  # Deliberate, reversible exit to the rescue OS (one-shot; BootOrder kept).
in {
  imports = [
    ../../../finix/desktop
    ./boot.nix
    ./graphical.nix
    ./hermes.nix
    ./opengrok-hop.nix
  ];

  # manzil dotfiles: native finix module (imported in finix/default.nix),
  # linker runs as a finit task gated on the user persist binds — the files
  # it writes (~/.config/rush/*.rush, ~/.config/ekko, …) live under those binds.
  # clobberByDefault: parity with the NixOS-side setting (flake-modules.nix)
  # — validated against the live manifest, where ~500 entries are clobber.
  networking.hostName = "y0usaf-desktop";

  finix = {
    diagnostics = {
      inherit diskUuid;
      fallbackDevices = ["/dev/nvme0n1p5"];
    };
    persistence.bindReplay = {
      enable = true;
      bindRoot = true;
      directories = map dirPath persistCfg.users.y0usaf.directories;
      files = map dirPath userFiles;
    };
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
    etc = {
      "modprobe.d/finix-desktop-blacklist.conf".text = ''
        blacklist nouveau
      '';
      "finix-stage2".text = "desktop-phase2.4\n";
      "profile.d/nh.sh".text = ''
        export NH_FLAKE=/home/y0usaf/finix
      '';
    };
    # Bare `nh os switch` targets this repo (nh resolves the hostname-keyed
    # nixosConfigurations.y0usaf-desktop = this finix system).
    systemPackages = [
      pkgs.nix
      pkgs.efibootmgr
      pkgs.git
      pkgs.curl
      pkgs.iproute2
      pkgs.iputils
      pkgs.procps
      pkgs.util-linux
      pkgs.vim
      # Manual one-time tool (run as root on the live system) to build the
      # @home-blank template that reset-home wipes @home back to on every boot.
      (pkgs.writeShellScriptBin "prep-home-blank" ''
        set -euo pipefail

        export PATH=${lib.makeBinPath [pkgs.btrfs-progs pkgs.coreutils pkgs.util-linux]}

        mountpoint -q /btrfs || {
          echo "prep-home-blank: /btrfs is not a mountpoint" >&2
          exit 1
        }

        if btrfs subvolume show /btrfs/@home-blank >/dev/null 2>&1; then
          if [ "''${1:-}" != "--force" ]; then
            echo "prep-home-blank: /btrfs/@home-blank already exists; rerun with --force to delete and recreate" >&2
            exit 1
          fi
          echo "prep-home-blank: --force: deleting existing /btrfs/@home-blank"
          btrfs subvolume delete /btrfs/@home-blank
        fi

        btrfs subvolume create /btrfs/@home-blank

        # y0usaf home root (0700, uid pinned to the NixOS value 1001) + the
        # data-subvol mountpoints + every allowlist ancestor dir, all
        # y0usaf:users. The leaf allowlist entries themselves are left to
        # persist-user-binds to create on first access.
        install -d -m 0700 -o 1001 -g users /btrfs/@home-blank/y0usaf
        while IFS= read -r dir; do
          [ -n "$dir" ] || continue
          install -d -m 0755 -o 1001 -g users "/btrfs/@home-blank/y0usaf/$dir"
        done <<'DIRS'
        ${lib.concatStringsSep "\n" (dataSubvolMounts ++ homeTemplateDirs)}
        DIRS

        chown -R 1001:users /btrfs/@home-blank/y0usaf
        echo "prep-home-blank: @home-blank ready ($((1 + ${toString (builtins.length (dataSubvolMounts ++ homeTemplateDirs))})) dirs)"
      '')
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
      # Kill USB autosuspend: AMD chipset xHCI (1022:43f7) resume
      # glitches caused repeated 'root hub lost power' + two data-fabric
      # sync floods. No autosuspend = no resume handshake = no trigger.
      "usbcore.autosuspend=-1"
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

      # /tmp gets its OWN tmpfs so a runaway build (cargo target dirs, nix-shell
      # scratch) fills 16G of throwaway space instead of the 4G root tmpfs —
      # a full root tmpfs wedges /etc, /var and activation itself.
      # NOTE: boot.tmp.useTmpfs/tmpfsSize is a systemd-only option (tmp.mount);
      # under finix it is a no-op, so the mount is declared here explicitly.
      # neededForBoot: mount.nix only emits mount tasks for those (gotcha #1).
      "/tmp" = {
        device = "none";
        fsType = "tmpfs";
        options = ["mode=1777" "size=16G" "nosuid" "nodev" "strictatime"];
        neededForBoot = true;
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
      "/home/y0usaf/dev" = subvolMount "@dev" [] // {neededForBoot = true;};
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
    # Crash-hunt capture: duplicate EVERY facility/severity to the server
    # (y0usaf-server 192.168.2.66:514, UDP) so an instant power-cut reboot
    # during `adb pair` still lands its kernel oops/MCE/AER before the box
    # dies. Desktop-only (common.nix is shared with the server). Local
    # /var/log stays durable via the /persist/var/log bind (common/persist.nix).
    sysklogd.extraConfig = "*.* @192.168.2.66:514";
    # Parity with the NixOS universe: real sshd on 2222; :22 stays free
    # for Tailscale SSH.
    openssh.settings.Port = [2222];
    nix-daemon = {
      settings = {
        # Phase-2a lesson: every nix invocation needed --extra-experimental-features.
        experimental-features = ["nix-command" "flakes"];
        # attic on the finix server: push cache for heavy local builds
        # (CUDA-class). LAN first (~40MiB/s push, ~180MB/s pull), tailnet
        # fallback for roaming (~100x slower but works).
        substituters = [
          "http://192.168.2.66:8787/cache"
          "http://y0usaf-server:8787/cache"
        ];
        trusted-public-keys = ["cache:lPd94Ltnv0ZYpkoK5UtQi/VrGkEtHRT7Af6jUzy3PLA="];
        # dead-cache stall tax: default 15s x 5 retries when the server is
        # off. 5s keeps the fallback fast; connect-only, transfers unaffected.
        connect-timeout = 5;
        # Dead/unreachable substituters degrade to a local build, not abort the run.
        fallback = true;
        # One attempt avoids ~40s stalls from default 5 retries x 5s timeout.
        download-attempts = 1;
      };
    };
  };


  # Same credentials as the NixOS install (impermanence keeps these paths).
  # uid PINNED to the NixOS value: this box's y0usaf is 1001 (not the 1000
  # finix would auto-allocate). First finix boot ran as 1000 and every
  # /persist + @home file (owned 1001) was foreign — libgit2 refused repos,
  # tools broke. Keep in lockstep with `id y0usaf` under NixOS forever.
  users.users.y0usaf.uid = 1001;
  users.users.root.passwordFile = "/persist/secrets/password-hashes/root";

  finit.tasks = {
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
  };

  # The desktop must accept pushed closures + local rebuilds.

  # Console-visible generation marker + deploy-path prover.
}
