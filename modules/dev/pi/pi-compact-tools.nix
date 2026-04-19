{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  cfg = config.user.dev.pi;
  piCompactToolsPkg = flakeInputs."pi-compact-tools".packages."${system}".default;
in {
  config = lib.mkIf cfg.enable {
    user.dev.pi.packageSources = lib.mkOrder 1200 ["${piCompactToolsPkg}"];
  };
}
