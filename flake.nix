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
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      overlays = [
        (final: prev: {
          inherit (uv2nix.packages.${system}) uv2nix;
        })
      ];
      config.allowUnfree = true;
    };

    ## ────── Profile Selection Based on Hostname ──────
    # Import all available profiles
    profiles = {
      "y0usaf-desktop" = import ./profiles/y0usaf-desktop {
        lib = pkgs.lib;
        inherit pkgs;
      };
      "y0usaf-laptop" = import ./profiles/y0usaf-laptop {
        lib = pkgs.lib;
        inherit pkgs;
      };
    };

    ## ────── Common Special Arguments for Modules ──────
    commonSpecialArgs = {
      inputs = self.inputs;
    };

    ## ────── Home Manager Configuration Helper ──────
    mkHomeConfiguration = username: system:
      home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = commonSpecialArgs;
        modules = [./home.nix];
      };
  in {
    ## ────── Formatter Setup ──────
    formatter.${system} = pkgs.alejandra;

    ## ────── NixOS Configurations ──────
    nixosConfigurations =
      builtins.mapAttrs
      (hostname: profile:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = commonSpecialArgs // {inherit profile;};
          modules = [
            ./profiles/${hostname}/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = commonSpecialArgs // {inherit profile;};
                users.${profile.username} = {
                  imports = [./home.nix];
                  home = {
                    stateVersion = profile.stateVersion;
                    homeDirectory = nixpkgs.lib.mkForce profile.homeDirectory;
                  };
                };
              };
            }
            chaotic.nixosModules.default
          ];
        })
      profiles;
  };
}
