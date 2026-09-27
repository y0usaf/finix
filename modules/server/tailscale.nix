{
  lib,
  pkgs,
  ...
}: {
  boot.kernelModules = ["tun"];

  finit = {
    tmpfiles.rules = ["d /run/tailscale 0755 root root"];

    tasks.tailscale-ssh = {
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
        echo "tailscale-ssh: tailscaled socket never came up" >&2
        exit 1
      '';
      log = true;
    };

    services.tailscaled = {
      description = "tailscale mesh VPN daemon";
      command = "${pkgs.tailscale}/bin/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock --port=41641";
      path = [
        pkgs.iproute2
        pkgs.iptables
        pkgs.procps
      ];
      conditions = ["net/lo/up"];
      log = true;
    };
  };

  environment.systemPackages = [pkgs.tailscale];
}
