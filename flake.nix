###############################################################################
# NixOS Flake Configuration
# System configuration and dependencies management for desktop environment
###############################################################################
{
  description = "NixOS configuration";

  ###########################################################################
  # Input Sources
  ###########################################################################
  inputs = {
    ## Core System Dependencies
    nixpkgs.url = "git+https://github.com/NixOS/nixpkgs?shallow=1&ref=nixos-unstable";
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

    ## Custom Resources
    deepin-dark-hyprcursor = {
      url = "github:y0usaf/Deepin-Dark-hyprcursor/9d7db02";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deepin-dark-xcursor = {
      url = "github:y0usaf/Deepin-Dark-xcursor/b3df394";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fast-fonts.url = "github:y0usaf/Fast-Font";
    hyprpaper = {
      url = "github:y0usaf/hyprpaper/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ## Development & Creative Tools
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    obs-image-reaction.url = "github:L-Nafaryus/obs-image-reaction";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    whisper-overlay = {
      url = "github:oddlama/whisper-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  ###########################################################################
  # System Outputs
  ###########################################################################
  outputs = inputs:
    import ./lib/flake/outputs.nix inputs;
}
