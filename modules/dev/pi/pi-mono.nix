{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  piPkg = flakeInputs."pi-mono".packages."${system}".default;
in {
  config = lib.mkIf config.user.dev.pi.enable {
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
