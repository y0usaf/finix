{lib, ...}: {
  options.services.tailscale.enableVPN = lib.mkEnableOption "Enable Tailscale VPN mesh network";
}
