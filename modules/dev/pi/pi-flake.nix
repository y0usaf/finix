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
  # No NixOS module import: finix's compat-import drops flake-input modules and
  # the whole programs.* namespace, so programs.pi never reached the desktop.
  # The pi package is declared once, in
  # hosts/y0usaf-desktop/finix/materialized-packages.nix.

  config = lib.mkIf config.user.dev.pi.enable {
    environment.systemPackages = [
      flakeInputs.pi-harness.packages."${pkgs.stdenv.hostPlatform.system}".default
    ];

    user.dev.pi = {
      readmePath = "${piSrc}/README.md";
      docsPath = "${piSrc}/docs";
      examplesPath = "${piSrc}/examples";
      # pi-flake renders its frames with ASCII glyphs by default (unicode is the
      # preset default; hosts can override via user.dev.pi.settings.symbols).
      settings = {
        symbols = {
          preset = "ascii";
          overrides = {};
        };
      };
    };
  };
}
