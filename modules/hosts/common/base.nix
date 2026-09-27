{
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
in {
  fonts.packages = [flakeInputs.fonts.packages.${system}.default];
}
