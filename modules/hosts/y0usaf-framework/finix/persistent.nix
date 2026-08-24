# Framework 16 Finix trial. NixOS keeps ownership of \EFI\limine and remains
# firmware default; modules/finix/esp-island.nix stages this closure under the
# independent \EFI\finix island for BootNext-only trials.
{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  userName = config.user.name;
  uid = 1000;
  homeDir = "/home/${userName}";
  diskUuid = "6ae685dc-540e-42f2-b30a-104a8aac0e27";
  espUuid = "6951-2BA6";
  btrfsOpts = ["relatime" "ssd" "discard=async" "space_cache=v2"];
  subvolMount = subvol: {
    device = "/dev/disk/by-uuid/${diskUuid}";
    fsType = "btrfs";
    options = ["subvol=${subvol}"] ++ btrfsOpts;
    neededForBoot = true;
  };

  persistCfg = ((import ../impermanence.nix) {}).environment.persistence."/persist";
  dirPath = entry:
    if builtins.isAttrs entry
    then entry.directory
    else entry;
  userPersist = persistCfg.users.${userName};
  userFiles = userPersist.files;

  splitPath = path: builtins.filter (part: part != "") (lib.splitString "/" path);
  properAncestors = path: let
    parts = splitPath path;
  in
    lib.init (lib.genList (index: lib.concatStringsSep "/" (lib.take (index + 1) parts)) (lib.length parts));
  dirnameOf = path: let
    parts = splitPath path;
  in
    lib.optional (lib.length parts > 1) (lib.concatStringsSep "/" (lib.init parts));
  fileTemplateDirs = builtins.concatMap (file: let
    dirname = dirnameOf (dirPath file);
  in
    dirname ++ lib.concatMap properAncestors dirname)
  userFiles;
  dirTemplateDirs = builtins.concatMap (directory: properAncestors (dirPath directory)) userPersist.directories;
  homeTemplateDirs = lib.unique (dirTemplateDirs ++ fileTemplateDirs);
  dataSubvolMounts = lib.unique (map
    (mountpoint: lib.removePrefix "${homeDir}/" mountpoint)
    (builtins.filter (mountpoint: lib.hasPrefix "${homeDir}/" mountpoint) (builtins.attrNames config.fileSystems)));
  healthPackage = pkgs.writeShellScriptBin "finix-framework-health" ''
    set -u
    export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.gnugrep pkgs.iproute2 pkgs.nftables pkgs.procps pkgs.shadow pkgs.util-linux]}
    failed=0
    check() {
      if "$@"; then
        printf 'ok: %s\n' "$*"
      else
        printf 'FAIL: %s\n' "$*" >&2
        failed=1
      fi
    }
    check test "$(cat /proc/1/comm)" = finit
    check grep -qx framework-trial-1 /etc/finix-stage2
    for mountpoint in /nix /persist /home /boot; do
      check mountpoint -q "$mountpoint"
    done
    check test "$(id -u ${userName})" = ${toString uid}
    check sh -c "ip -4 -br address show dev wlp191s0 scope global | grep -q '^wlp191s0.*UP'"
    check sh -c "ip -4 route show default | grep -q '^default '"
    check sh -c "ss -ltn | grep -q ':2222 '"
    check nft list table inet filter
    check test -e /dev/dri/renderD128
    if [ "''${1:-}" = --record ]; then
      out=/persist/finix-framework-boot
      mkdir -p "$out"
      stamp=$(date -u +%Y-%m-%dT%H-%M-%SZ)
      if [ "$failed" = 0 ]; then
        printf '%s\n' "$stamp" > "$out/healthy-$stamp"
      else
        printf '%s\n' "$stamp" > "$out/failed-$stamp"
      fi
      sync
    fi
    exit "$failed"
  '';
in {
  imports = [
    ../../../finix/desktop
    ./firewall.nix
    ./graphical.nix
    ./network.nix
    ./power.nix
  ];

  networking.hostName = "y0usaf-framework";

  finix = {
    diagnostics = {
      inherit diskUuid;
      fallbackDevices = ["/dev/nvme0n1p2"];
      logDir = "finix-framework-boot";
    };
    persistence.bindReplay = {
      enable = true;
      directories = map dirPath userPersist.directories;
      files = map dirPath userFiles;
    };
  };

  hardware = {
    firmware = [pkgs.linux-firmware];
    cpu.amd.updateMicrocode = true;
  };

  environment = {
    etc = {
      "finix-stage2".text = "framework-trial-1\n";
      "profile.d/nh.sh".text = ''
        export NH_FLAKE=/home/y0usaf/finix
      '';
      # Keep the passwordless sudo rule from common.nix so unattended system
      # builds can activate with `nh os switch`.
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
      pkgs.btrfs-progs
      flakeInputs.pi-flake.packages.${pkgs.stdenv.hostPlatform.system}.pi
      flakeInputs.nh.packages.${pkgs.stdenv.hostPlatform.system}.default
      healthPackage
      (pkgs.writeShellScriptBin "prep-home-blank" ''
        set -euo pipefail
        export PATH=${lib.makeBinPath [pkgs.btrfs-progs pkgs.coreutils pkgs.util-linux]}
        mountpoint -q /btrfs || { echo "prep-home-blank: /btrfs is not mounted" >&2; exit 1; }
        if btrfs subvolume show /btrfs/@home-blank >/dev/null 2>&1; then
          [ "''${1:-}" = --force ] || { echo "prep-home-blank: exists; pass --force" >&2; exit 1; }
          btrfs subvolume delete /btrfs/@home-blank
        fi
        btrfs subvolume create /btrfs/@home-blank
        install -d -m 0700 -o ${toString uid} -g users /btrfs/@home-blank/${userName}
        while IFS= read -r directory; do
          [ -n "$directory" ] || continue
          install -d -m 0755 -o ${toString uid} -g users "/btrfs/@home-blank/${userName}/$directory"
        done <<'DIRECTORIES'
        ${lib.concatStringsSep "\n" (dataSubvolMounts ++ homeTemplateDirs)}
        DIRECTORIES
        chown -R ${toString uid}:users /btrfs/@home-blank/${userName}
      '')
    ];
  };

  boot = {
    bootspec.enable = true;
    kernelPackages = pkgs.linuxPackages_latest;
    initrd.availableKernelModules = ["nvme" "xhci_pci" "thunderbolt" "usbhid" "usb_storage" "sd_mod"];
    kernelModules = ["kvm-amd" "amdgpu"];
    supportedFilesystems.efivarfs.enable = true;
    kernelParams = [
      "amd_pstate=active"
      "amdgpu.ppfeaturemask=0xffffffff"
      "amdgpu.dpm=1"
      "console=tty0"
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
        options = ["mode=1777" "size=8G" "nosuid" "nodev" "strictatime"];
        neededForBoot = true;
      };
      "/nix" = subvolMount "@nix";
      "/persist" = subvolMount "@persist";
      "/home" = subvolMount "@home";
      "/btrfs" = {
        device = "/dev/disk/by-uuid/${diskUuid}";
        fsType = "btrfs";
        options = ["subvolid=5"] ++ btrfsOpts;
        neededForBoot = true;
      };
      "/boot" = {
        device = "/dev/disk/by-uuid/${espUuid}";
        fsType = "vfat";
        options = ["fmask=0077" "dmask=0077"];
        neededForBoot = true;
      };
      "${homeDir}/.local/share/Steam" = subvolMount "@steam";
      # Match desktop: development trees live on dedicated durable subvolume.
      "${homeDir}/dev" = subvolMount "@dev";
    }
    // builtins.listToAttrs (map (directory: {
        name = directory;
        value = {
          device = "/persist${directory}";
          fsType = "btrfs";
          options = ["bind"];
          neededForBoot = true;
        };
      })
      (builtins.filter
        (directory: !lib.hasPrefix "/etc/" directory && directory != "/root")
        (map dirPath persistCfg.directories)));

  services = {
    docker.enable = true;
    openssh.settings.Port = [2222];
    nix-daemon = {
      settings = {
        experimental-features = ["nix-command" "flakes"];
        sandbox = true;
        auto-optimise-store = true;
        substituters = [
          "https://cache.nixos.org"
          "http://192.168.2.66:8787/cache"
          "http://y0usaf-server:8787/cache"
        ];
        trusted-public-keys = ["cache:lPd94Ltnv0ZYpkoK5UtQi/VrGkEtHRT7Af6jUzy3PLA="];
        connect-timeout = 5;
        fallback = true;
        download-attempts = 1;
      };
    };
  };

  users.users.${userName} = {
    inherit uid;
    extraGroups = ["video" "render" "seat" "networkmanager" "docker"];
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

  finit = {
    tasks = {
      framework-boot-health = {
        description = "record first-boot health after network and services settle";
        command = "${pkgs.writeShellScript "framework-boot-health" ''
          export PATH=${lib.makeBinPath [pkgs.coreutils]}
          for _ in $(seq 1 120); do
            if ${healthPackage}/bin/finix-framework-health; then
              exec ${healthPackage}/bin/finix-framework-health --record
            fi
            sleep 5
          done
          exec ${healthPackage}/bin/finix-framework-health --record
        ''}";
        log = true;
      };
    };
  };
}
