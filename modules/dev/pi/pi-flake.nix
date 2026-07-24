{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  piFlake = flakeInputs.pi-flake;
  # The base pi package is built from the upstream monorepo source; docs live there.
  piSrc = "${piFlake.packages."${pkgs.stdenv.hostPlatform.system}".pi.src}/packages/coding-agent";
in {
  imports = [piFlake.nixosModules.default];

  config = lib.mkIf config.user.dev.pi.enable {
    environment.systemPackages = [
      flakeInputs.pi-harness.packages."${pkgs.stdenv.hostPlatform.system}".default
    ];

    programs.pi = {
      enable = true;
      # Default bundle minus opt-in workflow variants.
      extensions = {
        "gecko-websearch" = true;
        rtk = true;
        minimal = true;
        interview = true;
        "tool-management" = true;
        webfetch = true;
        hashline = true;
        advisor = true;
        review = true;
        vcc = true;
        caveman = true;
      };
    };

    user.dev.pi = {
      readmePath = "${piSrc}/README.md";
      docsPath = "${piSrc}/docs";
      examplesPath = "${piSrc}/examples";
    };
  };
}
