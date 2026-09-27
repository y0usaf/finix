{
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
in {
  environment.systemPackages = [
    flakeInputs.emeraldian.packages."${system}".default
  ];
}
