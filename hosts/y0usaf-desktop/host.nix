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
  };
  user = {
    hardware.controllers.enable = true; # hidraw udev rules (finix-safe namespace)
    programs.discord.stable.pinLegacy = true;
    dev.work.linear-cli.settings = {
      workspace = "cook-unity";
    };
    gaming = {
      proton = {
        enable = true;
        nativeWayland = false;
        ntsync = true;
      };
      mangohud = {
        enable = true;
        enableSessionWide = true;
        refreshRate = 175;
      };
      runelite = {
        enable = true;
        scale = 2.0;
      };
    };
  };
}