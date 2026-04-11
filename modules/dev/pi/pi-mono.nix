{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  cfg = config.user.dev.pi;
  piPkg = flakeInputs."pi-mono".packages."${system}".default;
in {
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      piPkg
    ];

    user.dev.pi = {
      readmePath = "${piPkg}/share/pi/README.md";
      docsPath = "${piPkg}/share/pi/docs";
      examplesPath = "${piPkg}/share/pi/examples";
    };
  };
}
