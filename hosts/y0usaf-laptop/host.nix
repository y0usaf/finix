{
  pkgs,
  flakeInputs,
  ...
}: {
  fonts = {
    packages = [flakeInputs.fast-fonts.packages."${pkgs.stdenv.hostPlatform.system}".default];
    fontDir.enable = true;
  };
  hostname = "y0usaf-laptop";
  trustedUsers = ["y0usaf"];
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
