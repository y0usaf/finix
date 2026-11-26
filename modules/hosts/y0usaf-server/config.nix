{
  config,
  lib,
  pkgs,
  ...
}: let
  user = config.user.name;
  home = config.user.homeDirectory;
  inherit (config.user) runtimeDir;
  lloydPane = pkgs.writeShellScript "server-lloyd-pane" ''
    exec 3>"$1"
    rc=0
    omp-bot Lloyd 3>&- || rc=$?
    printf '%s\n' "$rc" >&3
  '';
  lloydWrapper = pkgs.writeShellScript "server-lloyd" ''
    set -eu
    tmux=${lib.getExe pkgs.tmux}
    rm=${pkgs.coreutils}/bin/rm
    mkfifo=${pkgs.coreutils}/bin/mkfifo
    head=${pkgs.coreutils}/bin/head
    cat=${pkgs.coreutils}/bin/cat
    fifo=${lib.escapeShellArg "${runtimeDir}/lloyd-tmux.fifo"}
    rcfile=${lib.escapeShellArg "${runtimeDir}/lloyd-tmux.rc"}
    "$rm" -f "$fifo" "$rcfile"
    "$mkfifo" -m 0600 "$fifo"
    "$tmux" -L lloyd kill-session -t lloyd 2>/dev/null || true
    reader=""
    cleanup() {
      "$tmux" -L lloyd kill-session -t lloyd 2>/dev/null || true
      [ -z "$reader" ] || kill "$reader" 2>/dev/null || true
      "$rm" -f "$fifo" "$rcfile"
      exit 0
    }
    trap cleanup TERM INT
    export PATH="/run/wrappers/bin:/etc/profiles/per-user/${user}/bin:${home}/.nix-profile/bin:/run/current-system/sw/bin"
    "$tmux" -L lloyd -f /dev/null new-session -d -s lloyd -x 140 -y 40 -- ${lloydPane} "$fifo"
    "$head" -n 1 "$fifo" >"$rcfile" &
    reader=$!
    wait "$reader" || true
    rc=$("$cat" "$rcfile" 2>/dev/null || true)
    "$rm" -f "$fifo" "$rcfile"
    exit "''${rc:-1}"
  '';
in {
  networking = {
    hostName = "y0usaf-server";
    staticFallback.address = "192.168.2.66/24";
    hosts = {
      ${config.tailnet.addresses.y0usaf-server} = ["forgejo" "syncthing-server"];
      ${config.tailnet.addresses.y0usaf-desktop} = ["syncthing-desktop"];
    };
  };

  environment.systemPackages = [pkgs.btrbk];

  finix.persistence.allowlist.directories = [
    "/var/lib/btrbk"
    "/var/lib/forgejo"
    "/var/lib/postgresql"
    "/var/lib/tailscale"
    "/var/log"
  ];

  boot.kernelModules = ["nf_tables"];

  services = {
    mdevd.enable = true;
    dhcpcd.enable = true;
    getty = {
      enable = true;
      ttys = ["tty1" "ttyS0"];
    };
    nix-daemon.settings.trusted-public-keys = ["cache:lPd94Ltnv0ZYpkoK5UtQi/VrGkEtHRT7Af6jUzy3PLA="];
    openssh.settings.Port = [2200];
    nftables = {
      enable = true;
      tables = {
        nixos-fw.enable = false;
        filter = {
          family = "inet";
          content = (import ../shared.nix {inherit lib;}).filterTable {
            tailscaleComment = "tailnet peers are authenticated";
            input = ''
              udp sport 67 udp dport 68 accept comment "dhcpcd lease traffic"

              iifname "eth0" tcp dport 2200 accept comment "sshd LAN fallback: this box has no console and no IPMI, so the tailnet must not be its only way in"

              tcp dport { 80, 443, 2222, 3000, 22000, 4200, 8787 } accept comment "2222 = forgejo ssh, NOT sshd (that is the eth0 rule); 8787 attic cache (LAN builds, tailnet too slow)"
              udp dport { 21027, 22000, 4200, 41641 } accept
              udp dport 8376 accept comment "tern remote sessions: desktop and phone peers dial in here"

              udp dport 51820 accept comment "wireguard mesh: desktop and phone peers dial in here"
              iifname "wg0" accept comment "wireguard mesh: traffic from mesh peers that ends here"
            '';
            forward = ''
              iifname "wg0" accept comment "wireguard mesh: this hub forwards between mesh peers"
              oifname "wg0" accept
            '';
          };
        };
      };
    };
    cron.enable = true;
  };

  user.account.shell = lib.mkForce "${pkgs.bashInteractive}/bin/bash";

  finix.persistence.homeServices = ["lloyd"];

  finit.services = {
    dhcpcd = {
      command = lib.mkForce (
        "${lib.getExe config.services.dhcpcd.package} -B "
        + lib.escapeShellArgs config.services.dhcpcd.extraArgs
      );
      type = lib.mkForce null;
      pid = lib.mkForce null;
    };
    lloyd = {
      description = "Lloyd omp-bot session";
      inherit user;
      group = "users";
      reload-signal = "none";
      respawn = true;
      restart-sec = 5;
      log = true;
      conditions = [config.user.runtimeDirReady "service/auth-router/running"];
      environment = {
        HOME = home;
        USER = user;
        SHELL = "${pkgs.bashInteractive}/bin/bash";
        TERM = "xterm-256color";
        XDG_CONFIG_HOME = "${home}/.config";
        XDG_DATA_HOME = "${home}/.local/share";
        XDG_STATE_HOME = "${home}/.local/state";
        XDG_CACHE_HOME = "${home}/.cache";
        XDG_RUNTIME_DIR = runtimeDir;
        AUTH_ROUTER_SOCKET = "${runtimeDir}/auth-router.sock";
      };
      command = "${lloydWrapper}";
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
