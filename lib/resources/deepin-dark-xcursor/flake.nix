{
  description = "Deepin Dark X11 Cursor Theme";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        themeName = "DeepinDarkV20-x11";
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "deepin-dark-xcursor";
          version = "1.0.0";
          src = ./.;

          sourceRoot = ".";

          installPhase = ''
            mkdir -p $out/share/icons/${themeName}
            cp -r ./cursors $out/share/icons/${themeName}/
            cp ./index.theme $out/share/icons/${themeName}/
          '';

          meta = {
            description = "Deepin Dark X11 cursor theme";
            homepage = "https://github.com/y0usaf/Deepin-Dark-xcursor";
            license = pkgs.lib.licenses.mit;
          };
        };
      }
    );
}