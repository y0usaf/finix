{
  description = "Fast Font Collection";
  
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {self, nixpkgs}: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    # We can expose the entire directory as a package source
    fastFontSource = pkgs.stdenv.mkDerivation {
      name = "fast-fonts";
      version = "1.0.0";
      src = self;
      
      installPhase = ''
        mkdir -p $out/share/fonts/truetype
        cp *.ttf $out/share/fonts/truetype/
      '';
    };
  };
}