{
  description = "Minimal flake wrapper for npins-based NixOS configuration";

  # No inputs - everything comes from npins
  inputs = {};

  outputs = _: let
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
