{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  cfg = config.user.dev.pi;
  piToolManagementPkg = flakeInputs."pi-tool-management".packages."${system}".default;
in {
  config = lib.mkIf cfg.enable {
    user.dev.pi.packageSources = lib.mkOrder 1300 ["${piToolManagementPkg}"];
  };
}
