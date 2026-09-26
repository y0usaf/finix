{pkgs, ...}: {
  services.nftables.configFile = pkgs.writeText "finix-desktop.nft" ''
    flush ruleset

    table inet filter {
      chain input {
        type filter hook input priority filter; policy drop;

        iifname "lo" accept
        iifname "tailscale0" accept comment "tailnet peers are authenticated; primary sshd:2222 path"
        ct state established,related accept
        ct state invalid drop
        meta l4proto { icmp, ipv6-icmp } accept

        udp sport 67 udp dport 68 accept comment "dhcpcd lease traffic"

        iifname "eno1" tcp dport 2222 accept comment "sshd LAN fallback: independent of tailscale being up. Wired NIC only - never wlp96s0"

        tcp dport { 25565, 27015, 27036 } accept comment "minecraft host; steam dedicatedServer; steam remotePlay"
        udp dport { 21027, 27015, 41641 } accept comment "syncthing LAN discovery; steam dedicatedServer; tailscale direct path (parity.nix --port=41641)"
        udp dport 27031-27036 accept comment "steam remotePlay"
        tcp dport 2234 accept comment "nicotine-plus Soulseek"
        udp dport 2234 accept comment "nicotine-plus Soulseek"
      }
      chain forward {
        type filter hook forward priority filter; policy drop;
      }
    }
  '';
}
