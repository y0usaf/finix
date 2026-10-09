{
  config,
  lib,
  pkgs,
  ...
}: let
  persistBind = dir: {
    device = "/persist${dir}";
    fsType = "btrfs";
    options = ["bind"];
    neededForBoot = true;
  };
in {
  networking = {
    hostName = "y0usaf-server";
    staticFallback.address = "192.168.2.66/24";
    hosts = {
      ${config.tailnet.addresses.y0usaf-server} = ["forgejo" "syncthing-server"];
      ${config.tailnet.addresses.y0usaf-desktop} = ["syncthing-desktop"];
    };
  };

  environment = {
    etc."finix-stage2".text = "persistent\n";
    systemPackages = [pkgs.btrbk];
  };

  fileSystems = {
    "/var/log" = persistBind "/var/log";
    "/var/lib/forgejo" = persistBind "/var/lib/forgejo";
    "/var/lib/postgresql" = persistBind "/var/lib/postgresql";
    "/var/lib/tailscale" = persistBind "/var/lib/tailscale";
    "/var/lib/btrbk" = persistBind "/var/lib/btrbk";
  };

  boot.kernelModules = ["nf_tables"];

  services = {
    mdevd.enable = true;
    dhcpcd.enable = true;
    getty.ttys = ["tty1" "ttyS0"];
    nix-daemon.settings.trusted-public-keys = ["cache:lPd94Ltnv0ZYpkoK5UtQi/VrGkEtHRT7Af6jUzy3PLA="];
    openssh.settings.Port = [2200];
    nftables = {
      enable = true;
      configFile = (import ../shared.nix {inherit lib pkgs;}).nftables "finix-server.nft" {
        tailscaleComment = "tailnet peers are authenticated";
        input = ''
          udp sport 67 udp dport 68 accept comment "dhcpcd lease traffic"

          iifname "eth0" tcp dport 2200 accept comment "sshd LAN fallback: this box has no console and no IPMI, so the tailnet must not be its only way in"

          tcp dport { 80, 443, 2222, 3000, 22000, 4200, 8787 } accept comment "2222 = forgejo ssh, NOT sshd (that is the eth0 rule); 8787 attic cache (LAN builds, tailnet too slow)"
          udp dport { 21027, 22000, 4200, 41641 } accept
        '';
      };
    };
    cron.enable = true;
  };

  users.users.${config.user.name}.shell = lib.mkForce "${pkgs.bashInteractive}/bin/bash";

  finit = {
    services.dhcpcd = {
      command = lib.mkForce (
        "${lib.getExe config.services.dhcpcd.package} -B "
        + lib.escapeShellArgs config.services.dhcpcd.extraArgs
      );
      type = lib.mkForce null;
      pid = lib.mkForce null;
    };
  };

  user.dev.paseo = {
    listenAddress = config.tailnet.addresses.y0usaf-server;
    relay.enable = false;
    environmentFiles = ["/home/y0usaf/Tokens/ANTHROPIC_API_KEY.txt"];
  };

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
}
