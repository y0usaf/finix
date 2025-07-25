let
  # Import npins sources
  sources = import ../npins;
  system = "x86_64-linux";

  # Build packages with overlays
  pkgs = import ./builders/pkgs.nix {
    inherit sources system;
  };

  # Import user configurations
  userConfigs = import ./builders/user-configs.nix {
    inherit pkgs inputs;
  };

  # Keep minimal inputs structure for compatibility
  inputs = {
    inherit (sources) nixpkgs;
    inherit (sources) disko;
    inherit (sources) nix-maid;
  };

  # Build NixOS configurations
  mkNixosConfigurations = import ./builders/nixos-config.nix {
    inherit sources pkgs system inputs userConfigs;
  };

  hostNames = ["y0usaf-desktop"];
in {
  # Formatter
  formatter.${system} = pkgs.alejandra;

  # NixOS configurations
  nixosConfigurations = mkNixosConfigurations hostNames;
}
