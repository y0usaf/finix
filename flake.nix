{
  description = "Minimal flake wrapper for npins-based NixOS configuration";

  inputs = {
    fast-fonts = {
      url = "github:y0usaf/Fast-Fonts";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
    fast-fonts,
  }: let
    lib-file = import ./lib {inherit fast-fonts;};
  in {
    # Just expose our npins-based nixosConfigurations
    inherit (lib-file) nixosConfigurations;

    # Expose formatter for flake check compatibility
    formatter.x86_64-linux = lib-file.formatter.x86_64-linux;

    # Expose the lib
    inherit (lib-file) lib;
  };
}
