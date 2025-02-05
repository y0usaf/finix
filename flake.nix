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
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    alejandra = {
      url = "github:kamadorueda/alejandra";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ## ────── Desktop Environment & Theming ──────
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hy3 = {
      url = "github:outfoxxed/hy3";
      inputs.hyprland.follows = "hyprland";
    };

    deepin-dark-hyprcursor = {
      url = "path:/home/y0usaf/nixos/pkg/deepin-dark-hyprcursor";
    };

    deepin-dark-xcursor = {
      url = "path:/home/y0usaf/nixos/pkg/deepin-dark-xcursor";
    };

    ## ────── Development & Creative Tools ──────
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    obs-image-reaction = {
      url = "github:L-Nafaryus/obs-image-reaction";
    };

    chaotic = {
      url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    };

    ## ────── System Styling ──────
    hyprpaper = {
      url = "github:y0usaf/hyprpaper/main";
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
    ...
  }: let
    ## ────── System & Package Configuration ──────
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config = {allowUnfree = true;};
    };

    ## ────── External Configurations ──────
    options = import ./profiles/options.nix; # (Imported for potential option flags)
    profile = import ./profiles/y0usaf-desktop.nix;

    ## ────── Common Special Arguments for Modules ──────
    commonSpecialArgs = {
      inherit profile;
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

    ## ────── User Home Manager Configuration ──────
    homeConfigurations.${profile.username} = mkHomeConfiguration profile.username system;

    ## ────── Machine-Specific NixOS Configuration ──────
    nixosConfigurations.${profile.hostname} = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = commonSpecialArgs;
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            extraSpecialArgs = commonSpecialArgs;
            users.${profile.username} = import ./home.nix;
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";
          };
        }
        chaotic.nixosModules.default
      ];
    };
  };
}
