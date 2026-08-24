{
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
in {
  fonts.packages = [flakeInputs.fonts.packages.${system}.default];
  user = {
    hardware.controllers.enable = lib.mkDefault true;
    programs.discord.stable.pinLegacy = lib.mkDefault true;
  };
}
