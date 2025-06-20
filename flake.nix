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

    nix-maid = {
      url = "github:viperML/nix-maid";
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
    obs-image-reaction.url = "github:L-Nafaryus/obs-image-reaction";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    ## Gaming
    nix-minecraft = {
      url = "github:Infinidoge/nix-minecraft";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ## Editor
    mnw = {
      url = "github:Gerg-L/mnw";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  ###########################################################################
  # System Outputs
  ###########################################################################
  outputs = inputs:
    import ./lib/flake/outputs inputs;
}
