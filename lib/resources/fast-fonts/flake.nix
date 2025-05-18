{
  description = "Fast Font Collection";
  
  # For when you're ready to publish to GitHub
  inputs = {
    # This is commented out for now to avoid errors in your local setup
    # Uncomment when you're ready to publish to GitHub
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  
  outputs = inputs@{ self, ... }:
    let
      # For when nixpkgs is properly included
      supportedSystems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
      
      # This will be used when nixpkgs is included
      mkFont = nixpkgs: system:
        nixpkgs.legacyPackages.${system}.stdenvNoCC.mkDerivation {
          pname = "fast-fonts";
          version = "1.0.0";
          src = self;
          
          installPhase = ''
            runHook preInstall
            
            mkdir -p $out/share/fonts/truetype
            install -m444 -Dt $out/share/fonts/truetype *.ttf
            
            mkdir -p $out/share/doc/fast-fonts
            install -m444 -Dt $out/share/doc/fast-fonts LICENSE README.md
            
            runHook postInstall
          '';
          
          meta = with nixpkgs.legacyPackages.${system}.lib; {
            description = "Fast Font Collection - TTF fonts";
            longDescription = ''Fast Font Collection provides optimized monospace and sans-serif fonts'';
            homepage = "https://github.com/y0usaf/fast-fonts"; # Update when you publish it
            platforms = platforms.all;
            license = licenses.mit;
          };
        };
    in {
      # For backward compatibility in your current setup
      fastFontSource = self;
      
      # This is commented out but shows the pattern you'd use when publishing
      # Uncomment and update when publishing to GitHub
      /*
      packages = nixpkgs.lib.genAttrs supportedSystems (system: {
        default = mkFont nixpkgs system;
      });
      */
    };
}