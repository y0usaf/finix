{
  config,
  lib,
  pkgs,
  ...
}: let
  user = config.user.name;
  home = config.user.homeDirectory;
  inherit (config.user) runtimeDir;
  lloydPath = "/run/wrappers/bin:/etc/profiles/per-user/${user}/bin:${home}/.nix-profile/bin:/run/current-system/sw/bin";
  lloydLaunch = pkgs.writeShellScript "server-lloyd-launch" ''
    export PATH=${lib.escapeShellArg lloydPath}
    export HOME=${lib.escapeShellArg home}
    export USER=${lib.escapeShellArg user}
    export SHELL=${lib.escapeShellArg "${pkgs.bashInteractive}/bin/bash"}
    export XDG_CONFIG_HOME=${lib.escapeShellArg "${home}/.config"}
    export XDG_DATA_HOME=${lib.escapeShellArg "${home}/.local/share"}
    export XDG_STATE_HOME=${lib.escapeShellArg "${home}/.local/state"}
    export XDG_CACHE_HOME=${lib.escapeShellArg "${home}/.cache"}
    export XDG_RUNTIME_DIR=${lib.escapeShellArg runtimeDir}
    export AUTH_ROUTER_SOCKET=${lib.escapeShellArg "${runtimeDir}/auth-router.sock"}
    exec omp-bot Lloyd
  '';
  lloydWrapper = pkgs.writeShellScript "server-lloyd" ''
    set -eu
    export PATH=${lib.escapeShellArg lloydPath}:${lib.makeBinPath [pkgs.coreutils pkgs.jq]}
    sock=${lib.escapeShellArg "${runtimeDir}/tern/daemon.sock"}
    export TERN_DAEMON_SOCKET="$sock"
    mkdir -p ${lib.escapeShellArg "${home}/dev"}

    tern daemon --socket "$sock" --login
    for _ in $(seq 1 50); do
      [ -S "$sock" ] && break
      sleep 0.1
    done
    [ -S "$sock" ]

    for dead in $(tern inspect --json | jq -r '.sessions[]?.tabs[]? | select(.name == "Lloyd") | .blocks[]? | select(.exited != null or .live != true) | .id'); do
      tern close "$dead" >/dev/null 2>&1 || true
    done

    block="$(tern inspect --json | jq -r '[ .sessions[]?.tabs[]? | select(.name == "Lloyd") | .blocks[]? | select(.live == true and .exited == null) | .id ] | first // empty')"
    if [ -z "$block" ]; then
      if tern inspect --json | jq -e '(.sessions | length) > 0' >/dev/null 2>&1; then
        out="$(tern new tab --json --cwd ${lib.escapeShellArg "${home}/dev"} -- ${lib.escapeShellArg "exec ${lloydLaunch}"})"
      else
        out="$(tern new session Default --json --cwd ${lib.escapeShellArg "${home}/dev"} -- ${lib.escapeShellArg "exec ${lloydLaunch}"})"
      fi
      block="$(printf '%s' "$out" | jq -r '.block')"
      tern rename "$block" Lloyd >/dev/null
    fi
    tern focus "$block" >/dev/null || true

    wait_pid=""
    cleanup() {
      [ -z "$wait_pid" ] || kill "$wait_pid" 2>/dev/null || true
      tern close "$block" >/dev/null 2>&1 || true
      exit 0
    }
    trap cleanup TERM INT

    tern wait "$block" --until exit &
    wait_pid=$!
    rc=0
    wait "$wait_pid" || rc=$?
    exit "$rc"
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

  environment.systemPackages = [
    pkgs.btrbk
    pkgs.wol
    (pkgs.writeShellScriptBin "wake-desktop" ''
      exec ${lib.getExe pkgs.wol} -i 192.168.2.255 58:11:22:b7:f0:29
    '')
  ];

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
