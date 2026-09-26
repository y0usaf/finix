{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  userName = config.user.name;
in {
  imports = [
    flakeInputs.finix.nixosModules.bluetooth
    flakeInputs.finix.nixosModules.polkit
    flakeInputs.finix.nixosModules.rtkit
    flakeInputs.finix.nixosModules.udisks2
    flakeInputs.finix.nixosModules.upower
  ];

  services = {
    bluetooth.settings = {
      General = {
        ControllerMode = "dual";
        FastConnectable = true;
      };
      Policy.AutoEnable = true;
    };
    polkit.adminIdentities = ["unix-user:${userName}"];

    udev.packages = [
      (pkgs.writeTextFile {
        name = "ntsync-udev";
        destination = "/etc/udev/rules.d/70-ntsync.rules";
        text = ''KERNEL=="ntsync", MODE="0644"'';
      })
    ];
  };

  boot.kernelModules = ["tun" "v4l2loopback" "zram" "uinput" "ntsync"];
  finit = {
    services.tailscaled = {
      description = "tailscale mesh VPN daemon";
      command = "${pkgs.tailscale}/bin/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock --port=41641";
      path = [pkgs.iproute2 pkgs.iptables pkgs.procps];
      conditions = ["net/lo/up"];
      log = true;
    };
    tasks = {
      tailscale-ssh = {
        description = "assert tailscale SSH rescue path";
        conditions = ["net/lo/up"];
        command = pkgs.writeShellScript "tailscale-ssh-assert" ''
          set -u
          export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.tailscale]}
          for _ in $(seq 1 60); do
            if tailscale --socket=/run/tailscale/tailscaled.sock set --ssh 2>/dev/null; then
              echo "tailscale-ssh: RunSSH asserted"
              exit 0
            fi
            sleep 2
          done
          echo "tailscale-ssh: could not assert --ssh" >&2
          exit 1
        '';
        log = true;
      };
      zram-swap = {
        description = "zram swap (50% RAM, zstd)";
        command = pkgs.writeShellScript "zram-swap" ''
          set -eu
          export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.util-linux pkgs.gnugrep pkgs.gawk pkgs.kmod]}
          modprobe zram || true
          grep -q zram /proc/swaps && exit 0
          mem_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
          dev=$(zramctl --find --size "$((mem_kb / 2))K" --algorithm zstd)
          mkswap "$dev" >/dev/null
          swapon -p 100 "$dev"
          echo "zram-swap: $dev active"
        '';
        log = true;
      };
      x11-socket-dir = {
        description = "fix /tmp mode + create X11 socket dirs";
        command = pkgs.writeShellScript "x11-socket-dir" ''
          export PATH=${lib.makeBinPath [pkgs.coreutils]}
          chmod 1777 /tmp
          install -d -m 1777 /tmp/.X11-unix /tmp/.ICE-unix
        '';
        log = true;
      };
    };
  };

  boot.extraModulePackages = [config.boot.kernelPackages.v4l2loopback];
  environment = {
    etc."modprobe.d/v4l2loopback.conf".text = ''
      options v4l2loopback exclusive_caps=1
    '';
    etc."ssl/certs/ca-certificates.crt".source = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
  };

  users.groups = {
    gamemode = {};
    bluetooth = {};
    lp = {};
    dialout = {};
  };
  users.users.${userName}.extraGroups = ["gamemode" "input" "bluetooth" "lp" "dialout"];
}
