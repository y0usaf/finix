{
  lib,
  pkgs,
  ...
}: let
  system = import ./system.nix {inherit lib pkgs;};
in {
  inherit (system) mkNixosConfigurations;
}
