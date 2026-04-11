{
  flakeInputs,
  lib,
  ...
}: {
  nixpkgs = {
    config = {
      allowUnfree = true;
      permittedInsecurePackages = [
        "qtwebengine-5.15.19"
        "electron-38.8.4"
      ];
      allowInsecurePredicate = pkg:
        lib.hasPrefix "librewolf" (pkg.pname or "")
        || lib.hasPrefix "electron" (pkg.pname or "");
    };
    overlays = [
      flakeInputs.claude-code-nix.overlays.default
    ];
  };
}
