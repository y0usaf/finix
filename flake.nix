#===============================================================================
#
#                     NixOS Flake Configuration
#
# Description:
#     Main flake configuration file defining the system's dependencies and
#     structure. Manages:
#     - Input sources and dependencies
#     - System configuration
#     - Home-manager integration
#     - Package overlays
#
# Author: y0usaf
# Last Modified: 2025
#
#===============================================================================
{
  description = "NixOS configuration";

  #-----------------------------------------------------------------------------
  # Input Sources
  #-----------------------------------------------------------------------------
  inputs = {
    # Core Dependencies
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Window Management
    hyprland.url = "github:hyprwm/Hyprland";
    hy3 = {
      url = "github:outfoxxed/hy3";
      inputs.hyprland.follows = "hyprland";
    };

    # Fabric Development
    fabric = {
      url = "github:Fabric-Development/fabric";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Python Tools
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # OBS Plugins
    obs-image-reaction.url = "github:L-Nafaryus/obs-image-reaction";

    # Development Tools
    alejandra = {
      url = "github:kamadorueda/alejandra";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  #-----------------------------------------------------------------------------
  # System Configuration
  #-----------------------------------------------------------------------------
  outputs = {
    self,
    nixpkgs,
    home-manager,
    obs-image-reaction,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    formatter.${system} = pkgs.alejandra;

    nixosConfigurations = {
      "y0usaf-desktop" = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
          globals = import ./globals.nix;
        };
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              extraSpecialArgs = {
                inherit inputs;
                hostName = "y0usaf-desktop";
                globals = import ./globals.nix;
              };
              users.y0usaf = import ./home.nix;
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
            };
          }
        ];
      };
    };
  };
}
