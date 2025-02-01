#─────────────────────── ❄️  NIXOS FLAKE CONFIG ───────────────────────#
# 🔄 System configuration and dependencies management                   #
# 🎯 Target: Desktop Environment for Development and Daily Use         #
#──────────────────────────────────────────────────────────────────────#
{
  description = "NixOS configuration";

  #── 📦 Input Sources & Dependencies ─────────────────────────────────#
  inputs = {
    #── 🎯 Core System Dependencies ──────────────────────────────────#
    # 📚 Main nixpkgs repository - using unstable channel
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # 🏠 Home Manager for user environment management
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # ✨ Nix code formatter
    alejandra = {
      url = "github:kamadorueda/alejandra";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #── 🪟 Desktop Environment & Theming ────────────────────────────#
    # 🖥️ Hyprland Wayland compositor
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # 📐 Hy3 - Hyprland tiling layout plugin
    hy3 = {
      url = "github:outfoxxed/hy3";
      inputs.hyprland.follows = "hyprland";
    };
    # 🖱️ Custom cursor themes
    deepin-dark-hyprcursor.url = "path:/home/y0usaf/nixos/pkg/deepin-dark-hyprcursor";
    deepin-dark-xcursor.url = "path:/home/y0usaf/nixos/pkg/deepin-dark-xcursor";

    #── 🛠️ Development & Creative Tools ─────────────────────────────#
    # 🐍 Python project management tools
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # 🚀 Fast Python package installer
    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # 🎥 OBS Studio plugin for image reactions
    obs-image-reaction.url = "github:L-Nafaryus/obs-image-reaction";
    # 🎁 Additional package repository
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
  };

  #── ⚙️ System Configuration Builder ──────────────────────────────────#
  outputs = {
    self,
    nixpkgs,
    home-manager,
    obs-image-reaction,
    hyprland,
    alejandra,
    hy3,
    chaotic,
    ...
  }: let
    # Define the target system architecture.
    system = "x86_64-linux";

    # Import pkgs with the desired configuration.
    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
      };
    };

    # Import globals once and reuse them.
    globals = import ./globals.nix;

    # Corrected: using "inherit" to pull both inputs and globals.
    commonSpecialArgs = {
      inherit globals;
      inputs = self.inputs;
    };

    # Function to create a consistent home-manager configuration.
    mkHomeConfiguration = username: system:
      home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = commonSpecialArgs;
        modules = [./home.nix];
      };
  in {
    #── 🎨 System Styling ───────────────────────────────────────────#
    formatter.${system} = pkgs.alejandra;

    #── 👤 User Environment Setup ──────────────────────────────────#
    homeConfigurations.${globals.username} = mkHomeConfiguration globals.username system;

    #── 🖥️ Machine-Specific Configuration ──────────────────────────#
    nixosConfigurations."y0usaf-desktop" = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = commonSpecialArgs;
      modules = [
        # Main system configuration.
        ./configuration.nix
        # Home Manager integration.
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            extraSpecialArgs = commonSpecialArgs;
            # User-specific configuration.
            users.y0usaf = import ./home.nix;
            # Global package management settings.
            useGlobalPkgs = true;
            useUserPackages = true;
            # Backup configuration.
            backupFileExtension = "backup";
          };
        }
        # Additional package repository.
        chaotic.nixosModules.default
      ];
    };
  };
}
