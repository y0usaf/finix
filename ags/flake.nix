{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    astal = {
      url = "github:aylur/astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ags = {
      url = "github:aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, astal, ags }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    packages.${system}.default = pkgs.stdenvNoCC.mkDerivation rec {
      name = "my-ags-shell";
      src = ./.;

      nativeBuildInputs = [
        ags.packages.${system}.default
        pkgs.wrapGAppsHook
        pkgs.gobject-introspection
      ];

      buildInputs = with astal.packages.${system}; [
        astal3
        io
        hyprland
      ];

      installPhase = ''
        mkdir -p $out/bin
        ags bundle app.tsx $out/bin/${name}
      '';
    };

    # Development shell
    devShells.${system}.default = pkgs.mkShell {
      buildInputs = with astal.packages.${system}; [
        ags.packages.${system}.default
        astal3
        io
        hyprland
        pkgs.gobject-introspection
      ];
      
      shellHook = ''
        echo "Astal development environment loaded"
        echo "Available: ags, astal3, io, hyprland"
        echo "Run: ags run app.tsx"
      '';
    };
  };
} 