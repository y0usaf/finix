{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.networking.staticFallback;
in {
  options.networking.staticFallback = {
    address = lib.mkOption {
      type = lib.types.str;
      example = "192.168.2.28/24";
      description = "Address with prefix length to assign when DHCP has not produced one.";
    };
    gateway = lib.mkOption {
      type = lib.types.str;
      default = "192.168.2.1";
      description = "Default gateway used with the static address.";
    };
  };

  config.finit.tasks.net-fallback = {
    description = "static IP fallback if DHCP fails";
    command = pkgs.writeShellScript "net-fallback" ''
      set -eu
      export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.iproute2 pkgs.gnugrep]}

      find_iface() {
        for dev in /sys/class/net/en* /sys/class/net/eth*; do
          [ -e "$dev" ] || continue
          basename "$dev"
          return 0
        done
        return 1
      }

      for _ in $(seq 1 45); do
        if ip -4 addr show scope global 2>/dev/null | grep -q 'inet '; then
          exit 0
        fi
        sleep 1
      done

      iface="$(find_iface)" || exit 1
      ip link set "$iface" up || true
      ip addr replace ${cfg.address} dev "$iface" || true
      ip route replace default via ${cfg.gateway} dev "$iface" || true
    '';
    conditions = ["net/lo/up"];
    log = true;
  };
}
