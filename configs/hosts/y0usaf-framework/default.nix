{
  flakeInputs,
  lib,
  pkgs,
  system,
  ...
}: {
  imports = [
    ../../../nixos
    ./hardware-configuration.nix
    ./impermanence.nix
    ./home-rollback.nix
    (flakeInputs.self + /configs/users/y0usaf-dev.nix)
  ];

  fonts = {
    packages = [flakeInputs.fast-fonts.packages."${system}".default];
    fontDir.enable = true;
  };
  hostname = "y0usaf-framework";
  trustedUsers = ["y0usaf"];
  homeDirectory = "/home/y0usaf";
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
