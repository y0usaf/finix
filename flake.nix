{
  description = "Minimal flake wrapper for npins-based NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    lib-file = import ./lib;
  in {
    # Just expose our npins-based nixosConfigurations
    inherit (lib-file) nixosConfigurations;

    # Expose formatter for flake check compatibility
    formatter.x86_64-linux = lib-file.formatter.x86_64-linux;

    # Expose the lib
    inherit (lib-file) lib;
  };
}
