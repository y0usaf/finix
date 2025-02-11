{
  description = "Simple configuration for uv2nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    pyproject-nix.url = "github:pyproject-nix/pyproject.nix";
    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
    };
  };

  outputs = { self, nixpkgs, pyproject-nix, uv2nix }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      overlays = [
        (final: prev: {
          inherit (uv2nix.packages.${system}) uv2nix;
        })
      ];
    };
  in {
    devShells.default = pkgs.mkShell {
      buildInputs = [ pkgs.uv2nix ];
    };
  };
}
