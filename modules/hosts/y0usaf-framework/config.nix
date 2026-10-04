{
  config,
  lib,
  pkgs,
  ...
}: let
  healthPackage = pkgs.writeShellScriptBin "finix-framework-health" ''
    set -u
    export PATH=${lib.makeBinPath [pkgs.bash pkgs.coreutils pkgs.gnugrep pkgs.iproute2 pkgs.nftables pkgs.procps pkgs.shadow pkgs.util-linux]}
    failed=0
    check() {
      if "$@"; then
        printf 'ok: %s\n' "$*"
      else
        printf 'FAIL: %s\n' "$*" >&2
        failed=1
      fi
    }
    check test "$(basename "$(readlink /proc/1/exe)")" = finit
    check grep -qx framework-trial-1 /etc/finix-stage2
    for mountpoint in /nix /persist /home /boot; do
      check mountpoint -q "$mountpoint"
    done
    check test "$(id -u ${config.user.name})" = 1000
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
  networking.hostName = "y0usaf-framework";

  environment = {
    etc = {
      "finix-stage2".text = "framework-trial-1\n";
      "elogind/logind.conf".text = lib.mkForce ''
        [Login]
        HandlePowerKey=poweroff
        HandleLidSwitch=suspend
        HandleLidSwitchExternalPower=suspend
        HandleLidSwitchDocked=ignore
        LidSwitchIgnoreInhibited=no
      '';
    };
    systemPackages = [pkgs.acpi healthPackage];
  };

  services = {
    elogind.enable = true;
    power-profiles-daemon = {
      enable = true;
      extraGroups = [config.services.seatd.group];
    };
    fwupd.enable = true;
    docker.enable = true;
    nix-daemon.settings = {
      sandbox = true;
      auto-optimise-store = true;
      substituters = lib.mkBefore ["https://cache.nixos.org"];
    };
    nftables.configFile = (import ../shared.nix {inherit lib pkgs;}).nftables "finix-framework.nft" {
      input = ''
        udp sport 67 udp dport 68 accept comment "DHCPv4 client"
        udp sport 547 udp dport 546 accept comment "DHCPv6 client"
        udp dport 41641 accept comment "Tailscale direct path"

        iifname "wlp191s0" tcp dport 22000 accept comment "Syncthing TLS transport"
        iifname "wlp191s0" udp dport { 21027, 22000 } accept comment "Syncthing discovery and QUIC"
      '';
      forward = ''
        iifname "docker0" accept
        oifname "docker0" accept
      '';
    };
  };

  programs = {
    brightnessctl.enable = true;
    zzz.enable = true;
  };

  users.users.${config.user.name} = {
    uid = 1000;
    extraGroups = ["docker"];
  };

  finit.tasks.framework-boot-health = {
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

  user = {
    services.syncthing.enabledFolders = ["tokens"];
    ui = {
      foot.lineHeight = "32px";
      tomoe = {
        layout = "sway";
        bar = {
          style = "gap";
          modules = ["time" "date" "battery" "network"];
          edges = ["bottom"];
        };
      };
    };
  };
}
