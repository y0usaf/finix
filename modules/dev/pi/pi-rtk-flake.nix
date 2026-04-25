{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  cfg = config.user.dev.pi;
  piRtkPkg = flakeInputs."pi-rtk-flake".packages."${system}".default;
in {
  config = lib.mkIf (cfg.enable && cfg.rtk.enable) {
    environment.systemPackages = [
      pkgs.rtk
    ];

    user.dev.pi.packageSources = lib.mkOrder 1100 ["${piRtkPkg}"];
  };
}
