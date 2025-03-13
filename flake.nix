###############################################################################
# NixOS Flake Configuration
# System configuration and dependencies management for desktop environment
# - Manages system dependencies and configurations
# - Supports dynamic profile loading
# - Configures desktop environment for development and daily use
###############################################################################
{
  description = "NixOS configuration";

  ###########################################################################
  # Input Sources
  ###########################################################################
  inputs = {
    ## Core System Dependencies
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Add flake-utils
    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    alejandra = {
      url = "github:kamadorueda/alejandra";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ## Desktop Environment & Theming
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hy3 = {
      url = "github:outfoxxed/hy3";
      inputs.hyprland.follows = "hyprland";
    };

    deepin-dark-hyprcursor.url = "path:/home/y0usaf/nixos/pkg/deepin-dark-hyprcursor";
    deepin-dark-xcursor.url = "path:/home/y0usaf/nixos/pkg/deepin-dark-xcursor";

    hyprpaper = {
      url = "github:y0usaf/hyprpaper/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ## Development & Creative Tools
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
    };

    obs-image-reaction.url = "github:L-Nafaryus/obs-image-reaction";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    # Claude Desktop for Linux
    claude-desktop.url = "github:k3d3/claude-desktop-linux-flake";
    claude-desktop.inputs.nixpkgs.follows = "nixpkgs";
    claude-desktop.inputs.flake-utils.follows = "flake-utils";
  };

  ###########################################################################
  # System Outputs
  ###########################################################################
  outputs = {
    self,
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    ## System & Package Configuration
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      overlays = [
        (final: prev: {
          inherit (inputs.uv2nix.packages.${system}) uv2nix;
        })
      ];
      config.allowUnfree = true;
    };

    ## Import profile utilities
    profileUtils = import ./modules/core/profiles.nix {
      lib = pkgs.lib;
      inherit pkgs;
    };

    ## Common Special Arguments for Modules
    commonSpecialArgs = {inputs = self.inputs;};
  in {
    ## Formatter Setup
    formatter.${system} = pkgs.alejandra;

    ## NixOS Configurations
    nixosConfigurations = profileUtils.mkNixosConfigurations {
      inputs = inputs;
      inherit system commonSpecialArgs;
    };

    ## Dynamic Home Manager Configurations
    homeConfigurations = profileUtils.mkHomeConfigurations {
      inputs = inputs;
      inherit pkgs commonSpecialArgs;
    };
  };
}
