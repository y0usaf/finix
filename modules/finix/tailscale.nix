{
  config,
  lib,
  pkgs,
  ...
}: let
  socket = "/run/tailscale/tailscaled.sock";
in {
  options.tailnet = {
    domain = lib.mkOption {
      type = lib.types.str;
      default = "tail865e88.ts.net";
      description = "MagicDNS suffix of the tailnet.";
    };
    addresses = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {
        y0usaf-server = "100.105.204.116";
        y0usaf-desktop = "100.90.54.18";
      };
      description = "Tailnet address of each machine, for the places that need an address rather than a name: rescue ssh, listen binds and hosts aliases.";
    };
  };

  config = {
    boot.kernelModules = ["tun"];

    environment.systemPackages = [pkgs.tailscale];

    programs.resolvconf = {
      enable = true;
      settings = {
        name_servers_append = ["1.1.1.1" "8.8.8.8"];
        resolv_conf_options = ["timeout:1"];
      };
    };

    finit = {
      tmpfiles.rules = ["d /run/tailscale 0755 root root"];

      services.tailscaled = {
        description = "tailscale mesh VPN daemon";
        command = "${pkgs.tailscale}/bin/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=${socket} --port=41641";
        path = [
          pkgs.iproute2
          pkgs.iptables
          pkgs.procps
          config.programs.resolvconf.package
        ];
        conditions = ["net/lo/up" "task/resolvconf/success"];
        log = true;
      };

      tasks.tailscale-prefs = {
        description = "assert tailscale SSH rescue path and MagicDNS";
        conditions = ["net/lo/up"];
        command = pkgs.writeShellScript "tailscale-prefs" ''
          set -u
          export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.tailscale]}
          for _ in $(seq 1 60); do
            if tailscale --socket=${socket} set --ssh --accept-dns=true 2>/dev/null; then
              echo "tailscale-prefs: RunSSH and CorpDNS asserted"
              exit 0
            fi
            sleep 2
          done
          echo "tailscale-prefs: tailscaled socket never came up" >&2
          exit 1
        '';
        log = true;
      };
    };
  };
}
