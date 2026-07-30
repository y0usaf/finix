# SCOPE (2026-07-30): this reaches exactly ONE system — the y0usaf-server
# NixOS rescue eval. There is no desktop NixOS eval anymore (flake.nix points
# nixosConfigurations.y0usaf-desktop at finixStaging.desktopPersistent), and
# `networking` is not on compat-import's whitelist, so nothing here has
# affected the running desktop since 2026-07-17. The desktop's real filter is
# hosts/y0usaf-desktop/finix/firewall.nix; the finix server's is the nftables
# block in hosts/y0usaf-server/finix/services.nix. Do not add desktop ports.
#
# Deletable when the server takeover flips and the rescue eval goes away
# (finix/NOTES.md, "Blocking work before the flip").
_: {
  config.networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      # :22 is Tailscale SSH's intercept port, opened here on all interfaces.
      # Kept as-is for the rescue path only: getting into a half-booted rescue
      # system matters more than tightening it. sshd itself is :2200 there and
      # is tailnet-only via modules/core/services/openssh.nix.
      22
      22000
    ];
    allowedUDPPorts = [
      22000
      21027
    ];
  };
}
