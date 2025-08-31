{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../../../modules/system
    ./hardware-configuration.nix
  ];

  # Install Fast Font system-wide (matching desktop)
  fonts.packages = [pkgs.fastFonts];
  users = ["y0usaf" "guest"];
  hostname = "y0usaf-laptop";
  homeDirectory = "/home/y0usaf";
  stateVersion = "24.11";
  timezone = "America/Toronto";
  profile = "default";

  # Laptop-specific hardware
  hardware = {
    bluetooth = {
      enable = true;
    };
    nvidia.enable = false; # Laptop uses AMD
    amdgpu.enable = true;
    # No display outputs config for laptop (uses built-in screen)
  };

  # Services (same as desktop but no PXE/nginx stuff)
  services = {
    docker.enable = true;
    waydroid.enable = false;
    controllers.enable = true;
    # No tftpd/nginx - desktop-specific
  };
}
