{
  lib,
  flakeInputs,
  ...
}: let
  permittedInsecurePackages = [
    "qtwebengine-5.15.19"
    "electron-38.8.4"
    "openssl-1.1.1w"
    "nodejs-20.20.2"
    "nodejs-slim-20.20.2"
  ];
in {
  nixpkgs = {
    config = {
      allowUnfree = true;
      inherit permittedInsecurePackages;
      allowInsecurePredicate = pkg:
        builtins.elem (pkg.name or "${pkg.pname or "name-missing"}-${pkg.version or "version-missing"}") permittedInsecurePackages
        || lib.hasPrefix "librewolf" (pkg.pname or "")
        || lib.hasPrefix "electron" (pkg.pname or "");
    };
    overlays = [
      flakeInputs.claude-code-nix.overlays.default
      (_: prev: {
        # Nix 2.34 incorrectly rejects "npm" as an invalid output when
        # validating outputChecks for the corepack output of nodejs-slim_20.
        # Rebuild nodejs_20 (symlinkJoin) without corepack, which is unused.
        # The out and npm outputs are already valid in the store.
        nodejs_20 = prev.symlinkJoin {
          pname = "nodejs";
          inherit (prev.nodejs-slim_20) version meta;
          passthru =
            prev.nodejs-slim_20.passthru
            // {
              inherit (prev.nodejs-slim_20) src;
            };
          paths = [
            prev.nodejs-slim_20
            prev.nodejs-slim_20.npm
          ];
        };
      })
    ];
  };
}
