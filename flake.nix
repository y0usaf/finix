{
  description = "Minimal flake wrapper for npins-based NixOS configuration";

  # No inputs - everything comes from npins
  inputs = {};

  outputs = {self}: {
    # Just expose our npins-based nixosConfigurations
    nixosConfigurations = (import ./lib).nixosConfigurations;

    # Expose formatter for flake check compatibility
    formatter.x86_64-linux = (import ./lib).formatter.x86_64-linux;
  };
}
