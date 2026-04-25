{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  cfg = config.user.dev.pi;
in {
  config = lib.mkIf (cfg.enable && cfg.rtk.enable) {
    environment.systemPackages = [
      pkgs.rtk
    ];

    user.dev.pi.packageSources = lib.mkOrder 1100 ["${flakeInputs."pi-rtk-flake".packages."${system}".default}"];
  };
}
