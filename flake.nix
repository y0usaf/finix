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

    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    darwin,
    ...
  } @ inputs: let
    linuxSystem = "x86_64-linux";
    darwinSystem = "aarch64-darwin";

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
      inherit inputs;
      system = linuxSystem;
      inherit nixpkgsConfig;
    };
  in {
    inherit (nixosLib) nixosConfigurations;

    darwinConfigurations.y0usaf-macbook = darwin.lib.darwinSystem {
      system = darwinSystem;
      modules = [
        {
          networking.hostName = "y0usaf-macbook";
          system.stateVersion = 4;
          nix.settings.experimental-features = ["nix-command" "flakes"];
        }
      ];
    };

    # Expose for easier access
    formatter.${linuxSystem} = nixpkgs.legacyPackages.${linuxSystem}.alejandra;
    formatter.${darwinSystem} = nixpkgs.legacyPackages.${darwinSystem}.alejandra;
  };
}
