{
  description = "Fast Font Collection";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in {
      packages = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.stdenvNoCC.mkDerivation {
          pname = "fast-fonts";
          version = "1.0.0";
          src = self;

          installPhase = ''
            mkdir -p $out/share/fonts/truetype
            install -m444 -Dt $out/share/fonts/truetype *.ttf
            mkdir -p $out/share/doc/fast-fonts
            install -m444 -Dt $out/share/doc/fast-fonts LICENSE README.md
          '';

          meta = with nixpkgs.legacyPackages.${system}.lib; {
            description = "Fast Font Collection - TTF fonts";
            longDescription = "Fast Font Collection provides optimized monospace and sans-serif fonts";
            homepage = "https://github.com/y0usaf/fast-fonts";
            platforms = platforms.all;
            license = licenses.mit;
          };
        };
      });
    };
}
