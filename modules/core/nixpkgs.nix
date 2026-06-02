{
  lib,
  flakeInputs,
  ...
}: let
  permittedInsecurePackages = [
    "qtwebengine-5.15.19"
    "electron-38.8.4"
    "openssl-1.1.1w"
  ];
in {
  nixpkgs = {
    config = {
      allowUnfree = true;
      inherit permittedInsecurePackages;
      allowInsecurePredicate = pkg: let
        name = pkg.name or "${pkg.pname or "name-missing"}-${pkg.version or "version-missing"}";
      in
        builtins.elem name permittedInsecurePackages
        || lib.hasPrefix "librewolf" (pkg.pname or "")
        || lib.hasPrefix "electron" (pkg.pname or "");
    };
    overlays = [
      flakeInputs.claude-code-nix.overlays.default
    ];
  };
}
