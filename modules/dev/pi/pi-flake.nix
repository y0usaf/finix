{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  piFlake = flakeInputs.pi-flake;
  # The base pi package is built from the upstream monorepo source; docs live there.
  piSrc = "${piFlake.packages.${pkgs.stdenv.hostPlatform.system}.pi.src}/packages/coding-agent";
in {
  imports = [piFlake.nixosModules.default];

  config = lib.mkIf config.user.dev.pi.enable {
    programs.pi = {
      enable = true;
      # Default bundle minus rlm.
      extensions = {
        "codex-fast" = true;
        "gecko-websearch" = true;
        rtk = true;
        compact = true;
        "tool-management" = true;
        webfetch = true;
        hashline = true;
        "minimal-editor" = true;
        "working-indicator" = true;
        advisor = true;
        review = true;
        vcc = true;
      };
    };

    user.dev.pi = {
      readmePath = "${piSrc}/README.md";
      docsPath = "${piSrc}/docs";
      examplesPath = "${piSrc}/examples";
    };
  };
}
