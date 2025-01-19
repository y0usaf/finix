#─────────────────────── ❄️  NIXOS FLAKE CONFIG ───────────────────────#
# 🔄 System configuration and dependencies management                   #
#──────────────────────────────────────────────────────────────────────#
{
  description = "NixOS configuration";

  #── 📦 Input Sources ──────────────────────#
  inputs = {
    # Core Dependencies
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #── 🪟 Window Management ─────────────────#
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #── 🐍 Python Tools ───────────────────────#
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #── 🎥 OBS Plugins ────────────────────────#
    obs-image-reaction.url = "github:L-Nafaryus/obs-image-reaction";

    #── 🛠️ Development Tools ─────────────────#
    alejandra = {
      url = "github:kamadorueda/alejandra";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #── 🔲 Hy3 ─────────────────────────────#
    hy3 = {
      url = "github:outfoxxed/hy3";
      inputs.hyprland.follows = "hyprland";
    };

    #── 🖱️ Cursor Theme ────────────────────────#
    deepin-dark-hyprcursor = {
      url = "path:/home/y0usaf/nixos/pkg/deepin-dark-hyprcursor";
      flake = false;
    };
    deepin-dark-xcursor = {
      url = "path:/home/y0usaf/nixos/pkg/deepin-dark-xcursor";
      flake = false;
    };
  };

  #── ⚙️ System Configuration ───────────────#
  outputs = {
    self,
    nixpkgs,
    home-manager,
    obs-image-reaction,
    hyprland,
    alejandra,
    hy3,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };

    globals = import ./globals.nix;

    mkHomeConfiguration = username: system:
      home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit inputs;
          globals = import ./globals.nix;
        };
        modules = [
          ./home.nix
        ];
      };
  in {
    formatter.${system} = pkgs.alejandra;

    homeConfigurations.${globals.username} = mkHomeConfiguration globals.username system;

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
