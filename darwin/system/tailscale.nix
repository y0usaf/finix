{pkgs, ...}: {
  # Tailscale configuration for macOS
  services.tailscale.enable = true;

  # Add tailscale package
  environment.systemPackages = with pkgs; [
    tailscale
  ];
}
