{
  description = "y0usaf's NixOS configuration";

  inputs = {
    # Pin to same revision as npins had
    nixpkgs.url = "github:NixOS/nixpkgs/7df7ff7d8e00218376575f0acdcc5d66741351ee";

    flake-utils.url = "github:numtide/flake-utils";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    smfh = {
      url = "github:feel-co/smfh";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fast-fonts = {
      url = "github:y0usaf/Fast-Fonts";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deepin-dark-xcursor = {
      url = "github:y0usaf/Deepin-Dark-xcursor";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    expedition-33-mods = {
      url = "github:y0usaf/Expedition-33-Mods";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zjstatus = {
      url = "github:dj95/zjstatus";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zjstatus-hints = {
      url = "github:y0usaf/zjstatus-hints";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    obs-image-reaction = {
      url = "github:y0usaf/obs-image-reaction";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    nvf = {
      url = "github:NotAShelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {nixpkgs, ...} @ inputs: let
    system = "x86_64-linux";

    # Centralized nixpkgs config
    nixpkgsConfig = {
      allowUnfree = true;
      cudaSupport = true;
      permittedInsecurePackages = [
        "qtwebengine-5.15.19"
      ];
    };

    # Import lib with flake inputs
    nixosLib = import ./nixos/lib {
      inherit inputs system nixpkgsConfig;
    };
  in {
    inherit (nixosLib) nixosConfigurations;

    # Expose for easier access
    formatter.${system} = nixpkgs.legacyPackages.${system}.alejandra;
  };
}
