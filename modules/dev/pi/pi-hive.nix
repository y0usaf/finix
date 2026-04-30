{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  piHivePkg = flakeInputs."pi-hive".packages."${system}".default;
in {
  config = lib.mkIf config.user.dev.pi.enable {
    environment.variables.PI_HIVE_PACKAGE = "${piHivePkg}";
    user.dev.pi.packageSources = lib.mkOrder 900 ["${piHivePkg}"];
  };
}
