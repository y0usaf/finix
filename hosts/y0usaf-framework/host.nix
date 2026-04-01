{
  flakeInputs,
  lib,
  pkgs,
  ...
}: {
  fonts = {
    packages = [flakeInputs.fast-fonts.packages."${pkgs.stdenv.hostPlatform.system}".default];
    fontDir.enable = true;
  };
  hostname = "y0usaf-framework";
  trustedUsers = ["y0usaf"];
  stateVersion = "24.11";
  timezone = "America/Toronto";

  environment.systemPackages = [pkgs.brightnessctl];

  # Secure Boot disabled until sbctl keys are enrolled post-install
  boot.loader.limine.secureBoot.enable = lib.mkForce false;

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
      virtualHostName = "syncthing-framework";
    };
  };
}
