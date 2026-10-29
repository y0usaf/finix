{
  lib,
  pkgs,
  ...
}: let
  cpuThreads = 32;
  perThread = 100000;
in {
  networking.hostName = "y0usaf-desktop";

  finix.persistence.allowlist.directories = [
    "/root"
    "/var/lib/btrbk"
    "/var/lib/sbctl"
  ];

  environment.systemPackages = [pkgs.btrbk];

  finit = {
    tmpfiles.rules = ["d /btrfs/_snapshots 0755 root root"];
    cgroups.build."cpu.idle" = 1;
    services = {
      nix-daemon.cgroup = lib.mkForce {
        build = {
          "cpu.max" = cpuThreads / 2 * perThread;
          "pids.max" = 1048576;
        };
      };
      nacre.cgroup.system."cpu.max" = cpuThreads / 4 * perThread;
    };
  };

  providers.scheduler = {
    backend = "cron";
    tasks.btrbk-snapshots = {
      interval = "hourly";
      command = "${lib.getExe pkgs.btrbk} -q -c ${pkgs.writeText "btrbk.conf" ''
        timestamp_format long
        snapshot_preserve_min 1d
        snapshot_preserve 48h 14d 4w

        volume /btrfs
          snapshot_dir _snapshots
          subvolume @persist
          subvolume @dev
      ''} run";
    };
  };

  services = {
    nftables.tables = {
      nixos-fw.enable = false;
      filter = {
        family = "inet";
        content = (import ../shared.nix {inherit lib pkgs;}).filterTable {
          tailscaleComment = "tailnet peers are authenticated; primary sshd:2222 path";
          input = ''
            udp sport 67 udp dport 68 accept comment "dhcpcd lease traffic"

            iifname "eno1" tcp dport 2222 accept comment "sshd LAN fallback: independent of tailscale being up. Wired NIC only - never wlp96s0"

            tcp dport { 25565, 27015, 27036 } accept comment "minecraft host; steam dedicatedServer; steam remotePlay"
            udp dport { 21027, 27015, 41641 } accept comment "syncthing LAN discovery; steam dedicatedServer; tailscale direct path (parity.nix --port=41641)"
            udp dport 27031-27036 accept comment "steam remotePlay"
            tcp dport 2234 accept comment "nicotine-plus Soulseek"
            udp dport 2234 accept comment "nicotine-plus Soulseek"

            iifname "eno1" tcp dport 9757 accept comment "mado for the Steam Frame"
            iifname "eno1" udp dport 9757 accept comment "mado for the Steam Frame"
          '';
        };
      };
    };
    sysklogd.extraConfig = "*.* @192.168.2.66:514";
    cron.enable = true;
    networkmanager.settings.keyfile.unmanaged-devices = "interface-name:wlp96s0";
  };

  user.uid = 1001;
  users.users.root.passwordFile = "/persist/secrets/password-hashes/root";

  networking.staticFallback.address = "192.168.2.28/24";

  user = {
    appearance = {
      termFontSize = 16;
      hyprcursorSize = 36;
    };

    ui.tomoe.bar.modules = ["media" "cpu" "memory" "time" "date" "gpu" "vram" "frame"];
    ui.tomoe.bar.style = "spine";
    ui.tomoe.bar.scale = 1.5;

    dev.nacre = {
      enable = true;
      app.enable = true;
    };

    gaming = {
      p4g.enable = true;
      solo-leveling-arise.enable = true;
      aethermancer.enable = true;
      elden-ring.enable = true;
      proton.enable = true;
      runelite.enable = true;
      aniimo = {
        enable = true;
        mods = ["camera" "movement" "rewards" "catch"];
      };
    };
  };
}
