{
  flakeInputs,
  system,
  ...
} @ args: {
  imports = [
    ../../../nixos
    ./hardware-configuration.nix
    (flakeInputs.self + /configs/users/y0usaf.nix)
  ];

  fonts = {
    packages = [flakeInputs.fast-fonts.packages.${system}.default];
    fontDir.enable = true;
  };
  hostname = "y0usaf-laptop";
  trustedUsers = ["y0usaf"];
  homeDirectory = "/home/y0usaf";
  stateVersion = "24.11";
  timezone = "America/Toronto";

  hardware = {
    bluetooth = {
      enable = true;
    };
    cpu.amd.enable = true;
    nvidia.enable = false;
    amdgpu.enable = true;
  };

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
