{
  description = "Fast Font Collection";
  
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {self, nixpkgs}: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    # Create a proper font package using font_types.mkFont
    fastFontSource = pkgs.runCommand "fast-fonts" {} ''
      mkdir -p $out/share/fonts/truetype
      cp ${self}/Fast_Mono.ttf $out/share/fonts/truetype/
      cp ${self}/Fast_Sans.ttf $out/share/fonts/truetype/
      cp ${self}/Fast_Sans_Dotted.ttf $out/share/fonts/truetype/
      cp ${self}/Fast_Serif.ttf $out/share/fonts/truetype/
      mkdir -p $out/share/doc/fast-fonts
      cp ${self}/LICENSE $out/share/doc/fast-fonts/
      cp ${self}/README.md $out/share/doc/fast-fonts/
    '';
  };
}