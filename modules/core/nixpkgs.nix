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
    ];
  };
}
