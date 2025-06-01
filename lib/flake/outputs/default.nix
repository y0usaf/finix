inputs: let
  inherit (inputs.nixpkgs) lib;

  ## Shared Configuration
  system = "x86_64-linux";

  ## Package Configuration
  pkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [
      (_final: prev: {
        fastFonts = inputs.fast-fonts.packages.${system}.default;
      })
    ];
    config.allowUnfree = true;
    config.cudaSupport = true;
  };

  ## Define helpers separately
  helpers = {
    importDirs = import ../../helpers/import-dirs.nix {inherit (pkgs) lib;};
    importModules = import ../../helpers/import-modules.nix {inherit (pkgs) lib;};
  };

  ## Import host utilities
  hostUtils = import ../default.nix {
    inherit (pkgs) lib;
    inherit pkgs;
    inherit helpers;
  };

  ## Import Hjem utilities
  hjemUtils = import ../hjem.nix {
    inherit (pkgs) lib;
    inherit pkgs;
    inherit helpers;
  };

  ## Common Special Arguments for Modules
  commonSpecialArgs = {
    inherit inputs;
    inherit (inputs) whisper-overlay disko fast-fonts;
    inherit helpers;
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

  ## Hjem Configurations
  hjemConfigurations = hjemUtils.mkHjemConfigurations {
    inherit inputs commonSpecialArgs;
  };
}
