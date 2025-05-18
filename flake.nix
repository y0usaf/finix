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
    nixpkgs.url = "git+https://github.com/NixOS/nixpkgs?shallow=1&ref=nixos-unstable";

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

    ## Disk Management
    disko = {
      url = "github:nix-community/disko";
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

    deepin-dark-hyprcursor.url = "path:/home/y0usaf/nixos/lib/resources/deepin-dark-hyprcursor";
    deepin-dark-xcursor.url = "path:/home/y0usaf/nixos/lib/resources/deepin-dark-xcursor";
    fast-fonts = {
      url = "path:/home/y0usaf/nixos/lib/resources/fast-fonts";
    };

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

    # Add whisper-overlay input
    whisper-overlay = {
      url = "github:oddlama/whisper-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  ###########################################################################
  # System Outputs
  ###########################################################################
  outputs = {
    self,
    nixpkgs,
    home-manager,
    whisper-overlay,
    disko,
    ...
  } @ inputs: let
    ## System & Package Configuration
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      overlays = [
        (final: prev: {
          inherit (inputs.uv2nix.packages.${system}) uv2nix;
          # Package fast-fonts properly following nixpkgs convention
          fastFonts = final.stdenvNoCC.mkDerivation {
            pname = "fast-fonts";
            version = "1.0.0";
            src = inputs.fast-fonts.fastFontSource;
            
            installPhase = ''
              runHook preInstall
              
              mkdir -p $out/share/fonts/truetype
              install -m444 -Dt $out/share/fonts/truetype $src/*.ttf
              
              mkdir -p $out/share/doc/fast-fonts
              install -m444 -Dt $out/share/doc/fast-fonts $src/LICENSE $src/README.md
              
              runHook postInstall
            '';
            
            meta = with final.lib; {
              description = "Fast Font Collection - TTF fonts";
              longDescription = ''Fast Font Collection provides optimized monospace and sans-serif fonts'';
              platforms = platforms.all;
              license = licenses.mit;
            };
          };
        })
      ];
      config.allowUnfree = true;
      config.cudaSupport = true;
    };

    ## Import host utilities
    hostUtils = import ./lib/flake {
      lib = pkgs.lib;
      inherit pkgs;
    };

    ## Common Special Arguments for Modules
    commonSpecialArgs = {
      inputs = self.inputs;
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
