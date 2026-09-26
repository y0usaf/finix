{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  diskUuid = "32ad19b5-88df-4e63-92d2-d5a150ad65c5";

  btrfsOpts = ["compress=zstd:3" "noatime" "ssd" "space_cache=v2"];
  subvolMount = subvol: extraOpts: {
    device = "/dev/disk/by-uuid/${diskUuid}";
    fsType = "btrfs";
    options = ["subvol=${subvol}"] ++ btrfsOpts ++ extraOpts;
  };

  persistCfg = config.finix.persistence.allowlist;
  dirPath = e:
    if builtins.isAttrs e
    then e.directory
    else e;
  userFiles = persistCfg.users.y0usaf.files;

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

  dataSubvolMounts =
    lib.unique (map (mp: lib.removePrefix "/home/y0usaf/" mp)
      (builtins.filter (mp: lib.hasPrefix "/home/y0usaf/" mp) (builtins.attrNames config.fileSystems)));
in {
  imports = [
    ../../../finix/desktop
    ./boot.nix
    ./graphical.nix
    ./network.nix
  ];

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

  hardware.firmware = [pkgs.linux-firmware];

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
      flakeInputs.pi-flake.packages."${pkgs.stdenv.hostPlatform.system}".pi
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
      "igc"
    ];
    supportedFilesystems = {
      btrfs.enable = true;
      efivarfs.enable = true;
    };
    kernelParams = [
      "amd_pstate=active"
      "mitigations=off"
      "console=tty0"
      "usbcore.autosuspend=-1"
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

      "/boot" = {
        device = "/dev/disk/by-uuid/31F2-1AE7";
        fsType = "vfat";
        options = ["fmask=0077" "dmask=0077" "noatime"];
        neededForBoot = true;
      };

      "/home/y0usaf/.local/share/Steam" = subvolMount "@steam" [] // {neededForBoot = true;};
      "/home/y0usaf/dev" = subvolMount "@dev" [] // {neededForBoot = true;};
      "/home/y0usaf/Pictures" = subvolMount "@pictures" [] // {neededForBoot = true;};
      "/home/y0usaf/DCIM" = subvolMount "@dcim" [] // {neededForBoot = true;};
      "/home/y0usaf/Music" = subvolMount "@music" [] // {neededForBoot = true;};
    }
    // (lib.genAttrs (builtins.filter (d: !lib.hasPrefix "/etc/" d && d != "/root")
      (map dirPath persistCfg.directories)) (d:
      (dir: {
        device = "/persist${dir}";
        fsType = "btrfs";
        options = ["bind"];
        neededForBoot = true;
      })
      d));

  finit.services.nix-daemon.cgroup.settings."cpu.max" = 2400000;

  services = {
    sysklogd.extraConfig = "*.* @192.168.2.66:514";
    openssh.settings.Port = [2222];
    nix-daemon = {
      settings = {
        experimental-features = ["nix-command" "flakes"];
        substituters = [
          "http://192.168.2.66:8787/cache"
          "http://y0usaf-server:8787/cache"
          "https://cuda-maintainers.cachix.org"
        ];
        trusted-public-keys = [
          "cache:lPd94Ltnv0ZYpkoK5UtQi/VrGkEtHRT7Af6jUzy3PLA="
          "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        ];
        connect-timeout = 5;
        fallback = true;
        download-attempts = 1;
      };
    };
  };

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

  system.activation.scripts.networkManagerConnections = {
    deps = ["etc"];
    text = ''
      src=/persist/etc/NetworkManager/system-connections
      dst=/etc/NetworkManager/system-connections
      ${pkgs.coreutils}/bin/install -d -m 0700 "$dst"
      if [ -d "$src" ]; then
        ${pkgs.findutils}/bin/find "$src" -maxdepth 1 -type f -exec \
          ${pkgs.coreutils}/bin/install -m 0600 -o root -g root {} "$dst/" \;
      fi
    '';
  };
}
