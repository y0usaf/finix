# Framework packet filter: Wi-Fi is untrusted. SSH is reachable through the
# authenticated tailscale0 path only; Syncthing keeps its authenticated LAN
# transport/discovery ports.
{pkgs, ...}: {
  services.nftables = {
    enable = true;
    configFile = pkgs.writeText "finix-framework.nft" ''
      flush ruleset

      table inet filter {
        chain input {
          type filter hook input priority filter; policy drop;

          iifname "lo" accept
          iifname "tailscale0" accept
          ct state established,related accept
          ct state invalid drop
          meta l4proto { icmp, ipv6-icmp } accept

          udp sport 67 udp dport 68 accept comment "DHCPv4 client"
          udp sport 547 udp dport 546 accept comment "DHCPv6 client"
          udp dport 41641 accept comment "Tailscale direct path"

          iifname "wlp191s0" tcp dport 22000 accept comment "Syncthing TLS transport"
          iifname "wlp191s0" udp dport { 21027, 22000 } accept comment "Syncthing discovery and QUIC"
        }

        chain forward {
          type filter hook forward priority filter; policy drop;
          iifname "docker0" accept
          oifname "docker0" accept
        }
      }
    '';
  };
}
