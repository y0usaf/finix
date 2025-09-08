{pkgs, ...}: {
  imports = [
    ../../../modules/system
    ./hardware-configuration.nix
    ../../users/y0usaf
    ../../users/guest
  ];

  # Install Fast Font system-wide (matching desktop)
  fonts.packages = [pkgs.fastFonts];
  hostname = "y0usaf-laptop";
  trustedUsers = ["y0usaf"];
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
