{
  config,
  lib,
  ...
}: {
  imports = [
    ./config.nix
    ./hosts.nix
  ];

  options.services.tailscale.enableVPN = lib.mkEnableOption "Enable Tailscale VPN mesh network";
}
