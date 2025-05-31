inputs: let
  inherit (inputs.nixpkgs) lib;
  
  ## Shared Configuration
  system = "x86_64-linux";
  
  ## Package Configuration
  pkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [
      (final: prev: {
        fastFonts = inputs.fast-fonts.packages.${system}.default;
        helpers = {
          importDirs = import ../../helpers/import-dirs.nix { inherit (prev) lib; };
          importModules = import ../../helpers/import-modules.nix { inherit (prev) lib; };
        };
      })
    ];
    config.allowUnfree = true;
    config.cudaSupport = true;
  };

  ## Import host utilities
  hostUtils = import ../default.nix {
    inherit (pkgs) lib;
    inherit pkgs;
  };

  ## Common Special Arguments for Modules
  commonSpecialArgs = {
    inherit inputs;
    inherit (inputs) whisper-overlay disko fast-fonts;
  };
in {
  ## Formatter Setup
  formatter.${system} = pkgs.alejandra;

  ## NixOS Configurations
  nixosConfigurations = hostUtils.mkNixosConfigurations {
    inherit inputs system commonSpecialArgs;
  };

  ## Dynamic Home Manager Configurations
  homeConfigurations = hostUtils.mkHomeConfigurations {
    inherit inputs pkgs commonSpecialArgs;
  };
}