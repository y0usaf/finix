{
  lib,
  pkgs,
  ...
}: let
  diskUuid = "9dfc38c4-5c75-471d-9106-80ff9175ab92";

  subvol = name: opts: {
    device = "/dev/disk/by-uuid/${diskUuid}";
    fsType = "btrfs";
    options = ["subvol=${name}"] ++ opts;
    neededForBoot = true;
  };

  persistBind = dir: {
    device = "/persist${dir}";
    fsType = "btrfs";
    options = ["bind"];
    neededForBoot = true;
  };
in {
  fileSystems = {
    "/home" = subvol "@home" ["compress=zstd" "noatime"];
    "/home/y0usaf/Music" = subvol "@music" [];
    "/home/y0usaf/DCIM" = subvol "@dcim" [];
    "/home/y0usaf/Pictures" = subvol "@pictures" [];
    "/btrfs" = {
      device = "/dev/disk/by-uuid/${diskUuid}";
      fsType = "btrfs";
      options = ["subvolid=5"];
      neededForBoot = true;
    };

    "/var/lib/forgejo" = persistBind "/var/lib/forgejo";
    "/var/lib/postgresql" = persistBind "/var/lib/postgresql";
    "/var/lib/tailscale" = persistBind "/var/lib/tailscale";
    "/var/lib/btrbk" = persistBind "/var/lib/btrbk";
  };

  boot.kernelModules = ["nf_tables"];

  services = {
    openssh.settings.Port = [2200];
    nftables = {
      enable = true;
      configFile = pkgs.writeText "finix-server.nft" ''
        flush ruleset

        table inet filter {
          chain input {
            type filter hook input priority filter; policy drop;

            iifname "lo" accept
            iifname "tailscale0" accept comment "tailnet peers are authenticated"
            ct state established,related accept
            ct state invalid drop
            meta l4proto { icmp, ipv6-icmp } accept

            udp sport 67 udp dport 68 accept comment "dhcpcd lease traffic"

            iifname "eth0" tcp dport 2200 accept comment "sshd LAN fallback: this box has no console and no IPMI, so the tailnet must not be its only way in"

            tcp dport { 80, 443, 2222, 3000, 22000, 4200, 8787 } accept comment "2222 = forgejo ssh, NOT sshd (that is the eth0 rule); 8787 attic cache (LAN builds, tailnet too slow)"
            udp dport { 21027, 22000, 4200, 41641 } accept
          }
          chain forward {
            type filter hook forward priority filter; policy drop;
          }
        }
      '';
    };
    cron.enable = true;
  };

  networking.hosts = {
    "100.105.204.116" = ["forgejo" "syncthing-server"];
    "100.90.54.18" = ["syncthing-desktop"];
  };

  user.dev.paseo.listenAddress = "100.105.204.116";

  providers.scheduler = {
    backend = "cron";
    tasks.btrbk-snapshots = {
      interval = "daily";
      command = "${lib.getExe pkgs.btrbk} -q -c ${pkgs.writeText "btrbk.conf" ''
        timestamp_format long
        snapshot_preserve_min 2d
        snapshot_preserve 7d 4w

        volume /btrfs
          snapshot_dir _snapshots
          subvolume @dcim
          subvolume @music
      ''} run";
    };
  };

  environment.systemPackages = [pkgs.btrbk];
}
