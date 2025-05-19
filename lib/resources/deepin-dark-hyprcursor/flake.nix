{
  description = "Deepin Dark Hyprcursor Theme";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        themeName = "DeepinDarkV20-hypr";
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "deepin-dark-hyprcursor";
          version = "1.0.0";
          src = ./.;

          sourceRoot = ".";
          dontFixTimestamps = true;

          installPhase = ''
            mkdir -p $out/share/icons/${themeName}
            if [ -d "./hyprcursors" ]; then
              cp -r ./hyprcursors $out/share/icons/${themeName}/
            elif [ -d "./HYPRCURSORS" ]; then
              cp -r ./HYPRCURSORS $out/share/icons/${themeName}/hyprcursors
            else
              find . -type d -iname "hyprcursors" -exec cp -r {} $out/share/icons/${themeName}/ \;
            fi
            cp ./manifest.hl $out/share/icons/${themeName}/
          '';

          meta = {
            description = "Deepin Dark Hyprland cursor theme";
            homepage = "https://github.com/y0usaf/Deepin-Dark-hyprcursor";
            license = pkgs.lib.licenses.mit;
          };
        };
      }
    );
}