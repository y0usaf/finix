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

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    darwin,
    home-manager,
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
        ./darwin
        home-manager.darwinModules.home-manager
        {
          networking.hostName = "y0usaf-macbook";
          networking.computerName = "y0usaf-macbook";
          system.stateVersion = 5;

          nix.settings = {
            experimental-features = ["nix-command" "flakes"];
            trusted-users = ["y0usaf" "@admin"];
          };

          # User configuration
          users.users.y0usaf = {
            name = "y0usaf";
            home = "/Users/y0usaf";
          };

          # Install Fast Font system-wide
          fonts.packages = [inputs.fast-fonts.packages.${darwinSystem}.default];

          # Configure home-manager
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";

          nixpkgs.config = nixpkgsConfig;
        }
      ];
    };

    # Expose for easier access
    formatter.${linuxSystem} = nixpkgs.legacyPackages.${linuxSystem}.alejandra;
    formatter.${darwinSystem} = nixpkgs.legacyPackages.${darwinSystem}.alejandra;
  };
}
