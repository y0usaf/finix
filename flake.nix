#─────────────────────── ❄️  NIXOS FLAKE CONFIG ───────────────────────#
# 🔄 System configuration and dependencies management                   #
# 🎯 Target: Desktop Environment for Development and Daily Use         #
#──────────────────────────────────────────────────────────────────────#
{
  description = "NixOS configuration";

  ####################################################################
  #                         INPUT SOURCES                            #
  ####################################################################
  inputs = {
    ## ────── Core System Dependencies ──────
    # Import the unstable branch of nixpkgs from GitHub.
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };

    # Import Home Manager which provides a user-centric approach to configuration.
    home-manager = {
      url = "github:nix-community/home-manager/master";
      # Use the same nixpkgs version as specified above to avoid mismatches.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Import Alejandra for code formatting tasks.
    alejandra = {
      url = "github:kamadorueda/alejandra";
      # Follow the same nixpkgs version to ensure consistency.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ## ────── Desktop Environment & Theming ──────
    # Hyprland: A dynamic Wayland compositor for modern desktops.
    hyprland = {
      url = "github:hyprwm/Hyprland";
      # Use the same nixpkgs dependency to align versioning.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hy3: Likely a module or configuration helper for Hyprland.
    hy3 = {
      url = "github:outfoxxed/hy3";
      # Follow the version provided by the hyprland input, ensuring compatibility.
      inputs.hyprland.follows = "hyprland";
    };

    # Deepin Dark Hyprcursor: Custom cursor theme for the Wayland-based Hyprland environment.
    deepin-dark-hyprcursor = {
      # Using a local path, indicating local development or customization.
      url = "path:/home/y0usaf/nixos/pkg/deepin-dark-hyprcursor";
    };

    # Deepin Dark Xcursor: Custom X11 cursor theme.
    deepin-dark-xcursor = {
      # Again, a local path is used, probably for experimental or personalized theming.
      url = "path:/home/y0usaf/nixos/pkg/deepin-dark-xcursor";
    };

    ## ────── Development & Creative Tools ──────
    # pyproject-nix: Tooling to help wrap Python projects with Nix.
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      # Ensure consistency by following the same version of nixpkgs.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # uv2nix: A utility that likely converts or integrates other configurations into Nix.
    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
    };

    # obs-image-reaction: Possibly a module to manage image reactions in OBS setups.
    obs-image-reaction = {
      url = "github:L-Nafaryus/obs-image-reaction";
    };

    # Chaotic: Provides access to bleeding-edge or unstable package versions.
    chaotic = {
      url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    };

    ## ────── System Styling ──────
    # Hyprpaper: Likely provides custom wallpapers or additional theming for your desktop.
    hyprpaper = {
      url = "github:y0usaf/hyprpaper/main";
      # Again, ensure that the same nixpkgs version is adhered to by following it.
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  ####################################################################
  #                        SYSTEM OUTPUTS                            #
  ####################################################################
  outputs = {
    self,
    nixpkgs,
    home-manager,
    obs-image-reaction,
    hyprland,
    alejandra,
    hy3,
    chaotic,
    hyprpaper,
    pyproject-nix,
    uv2nix,
    ...
  }: let
    ## ────── System & Package Configuration ──────
    # Define the target system architecture; adjust if you ever need a cross-compile.
    system = "x86_64-linux";
    # Import the Nix package collection using nixpkgs and set allowUnfree to true.
    pkgs = import nixpkgs {
      inherit system;
      # Use the correct overlay path
      overlays = [
        (final: prev: {
          inherit (uv2nix.packages.${system}) uv2nix;
        })
      ];
      config.allowUnfree = true;
    };

    ## ────── External Configurations ──────
    # Import additional configuration options from a local file.
    # This file can define various options used in the rest of your configuration.
    options = import ./profiles/options.nix {
      inherit pkgs;
      lib = nixpkgs.lib; # Use the library functions available in nixpkgs.
    };
    # Import the main profile for your desktop configuration.
    # This file should specify details like hostname and username.
    profile = import ./profiles/y0usaf-desktop.nix {
      lib = pkgs.lib;
      pkgs = pkgs; # Pass the packages set to your profile module.
    };

    ## ────── Common Special Arguments for Modules ──────
    # Create a set of common arguments that will be shared across several modules.
    # This simplifies passing the same arguments (like profile info and inputs) multiple times.
    commonSpecialArgs = {
      inherit profile;
      inputs = self.inputs;
    };

    ## ────── Home Manager Configuration Helper ──────
    # A helper function that instantiates a home-manager configuration for a given user and system.
    # This abstracts the repeated pattern of passing common arguments and module paths.
    mkHomeConfiguration = username: system:
      home-manager.lib.homeManagerConfiguration {
        inherit pkgs; # Use the same package set across configurations.
        extraSpecialArgs = commonSpecialArgs; # Merge in our shared settings.
        modules = [./home.nix]; # Import the main home configuration module.
      };
  in {
    ## ────── Formatter Setup ──────
    # Set up a formatting tool for the system. Here, Alejandra is assigned as the formatter.
    # This can be used to auto-format configuration files or source code.
    formatter.${system} = pkgs.alejandra;

    ## ────── User Home Manager Configuration ──────
    # Define the home manager configuration for the user defined in your profile.
    # This ensures that the user-specific environment is set up according to ./home.nix.
    homeConfigurations.${profile.username} = mkHomeConfiguration profile.username system;

    ## ────── Machine-Specific NixOS Configuration ──────
    # Create the system-wide NixOS configuration for your machine.
    # It integrates various modules like the basic configuration, home-manager, and unstable packages.
    nixosConfigurations.${profile.hostname} = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = commonSpecialArgs; # Pass in our common arguments.
      modules = [
        # Main machine configuration file – core of your NixOS setup.
        ./configuration.nix

        # Include the Home Manager module for managing per-user configurations.
        home-manager.nixosModules.home-manager

        {
          # Extended Home Manager configuration block.
          home-manager = {
            extraSpecialArgs = commonSpecialArgs; # Forward the common special arguments.
            # Link the user's home configuration by importing ./home.nix.
            users.${profile.username} = import ./home.nix;
            # The following settings decide which packages (global vs user-specific) are active.
            useGlobalPkgs = true;
            useUserPackages = true;
            # Filename extension to use when backing up generated configuration files.
            backupFileExtension = "backup";
          };
        }

        # Integrate the unstable packages provided by Chaotic, allowing use of cutting-edge software.
        chaotic.nixosModules.default
      ];
    };
  };
}
