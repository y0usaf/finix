{
  config,
  lib,
  pkgs,
  ...
}: let
  piPkg = pkgs.pi-coding-agent;
  # The nixpkgs package only ships the binary; docs live in the monorepo source.
  piSrc = "${piPkg.src}/packages/coding-agent";
in {
  config = lib.mkIf config.user.dev.pi.enable {
    environment.systemPackages = [piPkg];

    user.dev.pi = {
      readmePath = "${piSrc}/README.md";
      docsPath = "${piSrc}/docs";
      examplesPath = "${piSrc}/examples";
    };
  };
}
