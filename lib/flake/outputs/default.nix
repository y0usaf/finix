inputs: let
  lib = inputs.nixpkgs.lib;
  
  ## Shared Configuration
  system = "x86_64-linux";
  
  ## Package Configuration
  pkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [
      (final: prev: {
        fastFonts = inputs.fast-fonts.packages.${system}.default;
      })
    ];
    config.allowUnfree = true;
    config.cudaSupport = true;
  };

  ## Import host utilities
  hostUtils = import ../default.nix {
    lib = pkgs.lib;
    inherit pkgs;
  };

  ## Common Special Arguments for Modules
  commonSpecialArgs = {
    inputs = inputs;
    whisper-overlay = inputs.whisper-overlay;
    disko = inputs.disko;
    fast-fonts = inputs.fast-fonts;
  };
in {
  ## Formatter Setup
  formatter.${system} = pkgs.alejandra;

  ## NixOS Configurations
  nixosConfigurations = hostUtils.mkNixosConfigurations {
    inputs = inputs;
    inherit system commonSpecialArgs;
  };

  ## Dynamic Home Manager Configurations
  homeConfigurations = hostUtils.mkHomeConfigurations {
    inputs = inputs;
    inherit pkgs commonSpecialArgs;
  };
}