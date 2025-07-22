{
  description = "NixOS configuration";
  inputs = {
    nixpkgs.url = "git+https://github.com/NixOS/nixpkgs?ref=nixos-unstable";
    nix-maid = {
      url = "github:y0usaf/nix-maid/smfh-integration";
    };
    alejandra = {
      url = "github:kamadorueda/alejandra";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hy3 = {
      url = "github:outfoxxed/hy3";
      inputs.hyprland.follows = "hyprland";
    };
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
    obs-image-reaction.url = "github:L-Nafaryus/obs-image-reaction";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    nix-minecraft = {
      url = "github:Infinidoge/nix-minecraft";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mnw = {
      url = "github:Gerg-L/mnw";
    };
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs:
    import ./lib/flake/outputs inputs;
}
