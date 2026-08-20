{
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
in {
  fonts.packages = [flakeInputs.fonts.packages.${system}.default];

  user = {
    paths.flake.path = "/home/y0usaf/finix";
    hardware.controllers.enable = true;
    programs.discord.stable.pinLegacy = true;
  };
}
