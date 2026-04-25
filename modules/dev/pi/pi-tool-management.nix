{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
in {
  config = lib.mkIf config.user.dev.pi.enable {
    user.dev.pi.packageSources = lib.mkOrder 1300 ["${flakeInputs."pi-tool-management".packages."${system}".default}"];
  };
}
