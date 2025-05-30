###############################################################################
# Flake Utilities
# Complete flake outputs and configuration functions
###############################################################################
{
  lib,
  pkgs,
  ...
}: let
  # Import individual modules
  shared = import ./shared.nix {inherit lib pkgs;};
  home = import ./home.nix {inherit lib pkgs;};
  system = import ./system.nix {inherit lib pkgs;};
in {
  # Export configuration functions
  inherit (shared) hostNames systemConfigs homeConfigs;
  inherit (home) mkHomeConfigurations;
  inherit (system) mkNixosConfigurations;
  
  # Complete outputs function
  mkOutputs = inputs: let
    ## System Configuration
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

    ## Import host utilities (self-reference to get the functions)
    hostUtils = import ./. {
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
  };
}