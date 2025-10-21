{
  flakeInputs,
  system,
  ...
}: {
  imports = [
    ../../../modules/system
    ./hardware-configuration.nix
    ../../users/y0usaf
  ];

  # Install Fast Font system-wide
  fonts = {
    packages = [flakeInputs.fast-fonts.packages.${system}.default];
    fontDir.enable = true;
  };
  hostname = "y0usaf-laptop";
  trustedUsers = ["y0usaf"];
  homeDirectory = "/home/y0usaf";
  stateVersion = "24.11";
  timezone = "America/Toronto";

  # Laptop-specific hardware
  hardware = {
    bluetooth = {
      enable = true;
    };
    nvidia.enable = false; # Laptop uses AMD
    amdgpu.enable = true;
    # No display outputs config for laptop (uses built-in screen)
  };

  # Services
  services = {
    docker.enable = true;
    waydroid.enable = false;
    controllers.enable = true;
    tailscale.enableVPN = true;
    syncthing-proxy = {
      enable = true;
      virtualHostName = "syncthing-laptop";
    };
  };
}
