{
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
in {
  fonts = {
    packages = [flakeInputs.fonts.packages."${system}".default];
    fontDir.enable = true;
  };
  hostname = "y0usaf-framework";
  trustedUsers = ["y0usaf"];
  stateVersion = "24.11";
  timezone = "America/Toronto";

  environment.systemPackages = [pkgs.brightnessctl];

  user.programs.discord.stable.package =
    (import flakeInputs.nixpkgs-discord-legacy {
      inherit system;
      config.allowUnfree = true;
    }).discord;

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
