# Desktop packet filter — SINGLE SOURCE OF TRUTH. finix-native module
# (nftables), desktop-only. Imported directly by modules/finix/default.nix
# and excluded from the recursive walk (it is not a NixOS module, so the
# compat shim must never see it).
#
# Fixes DRIFT-AUDIT finding #1: between 2026-07-17 (finix switch) and this
# commit the desktop ran with NO packet filter at all. `networking` is not on
# compat-import's whitelist, so every `networking.firewall.*` declaration in
# ../../../modules was silently discarded, and modules/finix/default.nix
# imported the upstream `nftables` module into serverPersistent only. Live
# proof at audit time: nft / iptables / ip6tables all absent from the system.
#
# This file is NOT a mirror. The NixOS-side declarations it replaces were
# deleted or de-scoped in the same commit, so there is no second copy to keep
# in agreement (DRIFT-AUDIT's conclusion: derived mirrors hold, hand-copied
# ones drift). Ports live here and nowhere else for this host.
#
# SUPERSEDED (declarations removed/re-scoped in the same commit):
#   hosts/y0usaf-desktop/host.nix        TCP 25565      (minecraft host)
#   modules/gaming/steam.nix             remotePlay + dedicatedServer
#                                        openFirewall -> the steam ports below
#   modules/core/networking/firewall.nix now server-rescue-only (see its header)
#
# DELIBERATELY NOT HONOURED, with reasons — these were declared NixOS-side and
# are wrong for this host, so restating them would be cargo cult:
#
#   TCP 22    modules/core/networking/firewall.nix opened :22 globally. Nothing
#             binds :22 here — tailscaled intercepts tailnet:22 for Tailscale
#             SSH, which arrives on tailscale0 and is accepted by the blanket
#             rule below. A global hole would protect nothing.
#   TCP 2222  NOT globally. sshd gets TWO scoped paths instead, below:
#             tailscale0 (primary, any network) + eno1 (LAN fallback). See the
#             "WHY TWO SSH PATHS" block.
#   TCP/UDP   syncthing's sync port. finix runs syncthing with only
#   22000     --gui-address (finix/audio.nix), so it binds a RANDOM high port
#             (35171 at audit time) — opening 22000 would land on nothing.
#             Inbound sync is therefore impossible either way; the desktop
#             dials out to y0usaf-server (which does open 22000). UDP 21027
#             below still gets LAN peer discovery working.
#   TCP       nginx + syncthing-proxy are enabled in host.nix but `services`
#   80/443    is not whitelisted, so no nginx runs here. Nothing to open.
#
# WHY TWO SSH PATHS (2026-07-30, deliberate divergence from the NixOS-side
# comment in modules/core/services/openssh.nix, which is now scoped to the
# server RESCUE eval and says "tailnet only; never LAN/WAN"):
#
# tailscale0 is the primary path and the only one that works off-LAN. It is
# also a single point of failure with remote dependencies — control-plane
# outage, node-key expiry, a tailscaled crash after an update, DERP trouble.
# When you are on the same LAN there is no reason for shell access to depend
# on any of that, so eno1:2222 is a second, independent path.
#
# Scoped by iifname, not left global, for two reasons: it keeps sshd off
# wlp96s0 should wifi ever come up on a network we do not control, and it
# avoids pinning a subnet literal that DHCP could silently invalidate — a
# fallback that fails silently is worse than no fallback.
#
# Risk accepted: an attacker already on the LAN can reach sshd. Auth is
# key-only (openssh.nix: PasswordAuthentication = false, PermitRootLogin =
# no) and the box is behind NAT, so this is not internet exposure.
#
# forward policy drop is safe today: no dockerd, no container bridges, and
# net.ipv4.ip_forward = 0. Rootless podman (pasta/slirp4netns) does not use
# the forward hook. Revisit if docker or a bridge network ever lands.
{pkgs, ...}: {
  services.nftables = {
    enable = true;
    configFile = pkgs.writeText "finix-desktop.nft" ''
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
  };
}
