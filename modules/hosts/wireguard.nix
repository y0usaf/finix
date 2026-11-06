{
  config,
  lib,
  pkgs,
  ...
}: let
  host = config.networking.hostName;
  key = "/var/lib/wireguard/wg0.key";
  hub = "y0usaf-server";

  mesh = {
    y0usaf-server = {
      address = "10.44.0.1";
      publicKey = "TAfVYr9KQOsVJ4JPJRZ+N6qZnKN9U3jgqHVS64dL+nM=";
      endpoint = "192.168.2.66:51820";
    };
    y0usaf-desktop = {
      address = "10.44.0.2";
      publicKey = "OutYhdciDE4/l0tudd+QFINtAKmIldvoiPm17hy0gxQ=";
      endpoint = null;
    };
    phone = {
      address = "10.44.0.3";
      publicKey = "JFTSgHniL6Rr+4jmYHtkSsWpW0NWgBOFpvcKAZm8Q3k=";
      endpoint = null;
    };
  };

  me = mesh.${host};
  peers = lib.filterAttrs (name: _: name != host) mesh;

  peerArgs =
    if host == hub
    then lib.concatMapStrings (p: " peer ${p.publicKey} allowed-ips ${p.address}/32") (lib.attrValues peers)
    else " peer ${mesh.${hub}.publicKey} endpoint ${mesh.${hub}.endpoint} allowed-ips 10.44.0.0/24 persistent-keepalive 25";
in {
  boot.kernelModules = ["wireguard"];
  environment.systemPackages = [pkgs.wireguard-tools];

  finix.persistence.allowlist.directories = ["/var/lib/wireguard"];

  finit.tasks.wireguard = {
    description = "WireGuard mesh, wg0 (${me.address}/24)";
    conditions = ["net/lo/up"];
    log = true;
    command = pkgs.writeShellScript "wireguard-wg0" ''
      set -eu
      ip=${pkgs.iproute2}/bin/ip
      wg=${pkgs.wireguard-tools}/bin/wg
      $ip link show wg0 >/dev/null 2>&1 || $ip link add dev wg0 type wireguard
      $wg set wg0 private-key ${key} listen-port 51820${peerArgs}
      $ip -4 addr replace ${me.address}/24 dev wg0
      $ip link set wg0 mtu 1420 up
      ${lib.optionalString (host == hub) "${pkgs.procps}/bin/sysctl -q -w net.ipv4.ip_forward=1"}
    '';
  };
}
