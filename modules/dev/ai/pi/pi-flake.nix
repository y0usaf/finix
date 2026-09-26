{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  piFlake = flakeInputs.pi-flake;
  piSrc = "${piFlake.packages."${pkgs.stdenv.hostPlatform.system}".pi.src}/packages/coding-agent";
in {
  config = lib.mkIf config.user.dev.pi.enable {
    environment.systemPackages = [
      flakeInputs.pi-harness.packages."${pkgs.stdenv.hostPlatform.system}".default
    ];

    user.dev.pi = {
      readmePath = "${piSrc}/README.md";
      docsPath = "${piSrc}/docs";
      examplesPath = "${piSrc}/examples";
      settings = {
        symbols = {
          preset = "ascii";
          overrides = {};
        };
        recap = {
          placement = "above";
        };
      };
    };
  };
}
