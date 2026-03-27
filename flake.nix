{
  description = "y0usaf's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    bayt = {
      url = "github:y0usaf/bayt";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fast-fonts = {
      url = "github:y0usaf/Fast-Fonts";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    cursors = {
      url = "github:y0usaf/cursors";
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

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
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

    mango = {
      url = "github:DreamMaoMao/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    handy = {
      url = "github:cjpais/Handy/f1516d92281c27ba5971c8da4a2356e5f084b0db";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-code-nix = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tweakcc = {
      url = "github:y0usaf/tweakcc?ref=feat/nix-module";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    codex-desktop-linux = {
      url = "github:y0usaf/codex-desktop-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agent-slack = {
      url = "github:stablyai/agent-slack";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
    };

    gpui-shell = {
      url = "github:andre-brandao/gpui-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    strictix = {
      url = "path:/home/y0usaf/Dev/strictix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    patchix = {
      url = "path:/home/y0usaf/Dev/patchix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agent-harness = {
      url = "path:/home/y0usaf/Dev/Agent-Harness";
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
    legacyPkgs = nixpkgs.legacyPackages;

    commonNixpkgsConfig = {
      allowUnfree = true;
      permittedInsecurePackages = [
        "qtwebengine-5.15.19"
      ];
      allowInsecurePredicate = pkg: nixpkgs.lib.hasPrefix "librewolf" (pkg.pname or "");
    };

    darwinPkgs = legacyPkgs."${darwinSystem}";
    fastFonts = inputs.fast-fonts;
  in {
    inherit
      (import ./nixos/lib {
        inherit inputs;
        system = linuxSystem;
        nixpkgsConfig = commonNixpkgsConfig;
      })
      nixosConfigurations
      ;

    darwinConfigurations.y0usaf-macbook = darwin.lib.darwinSystem {
      system = darwinSystem;
      modules = [
        {
          _module.args = {
            inherit inputs;
            genLib = import ./lib/generators {
              inherit (darwinPkgs) lib;
              pkgs = darwinPkgs;
            };
            iosevkaSlab = darwinPkgs.stdenvNoCC.mkDerivation {
              pname = "fast-iosevka-slab";
              version = "1.0.0";
              src = fastFonts;

              installPhase = ''
                mkdir -p $out/share/fonts/truetype
                cp -f $src/fonts/Fast_IosevkaSlab.ttf $out/share/fonts/truetype/ || true
              '';
            };
            inherit (inputs) nvf;
          };
        }
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
          fonts.packages = [fastFonts.packages."${darwinSystem}".default];

          # Configure home-manager
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";
          };

          nixpkgs.config = commonNixpkgsConfig;
        }
      ];
    };

    # Expose for easier access
    formatter."${linuxSystem}" = legacyPkgs."${linuxSystem}".alejandra;
    formatter."${darwinSystem}" = darwinPkgs.alejandra;
  };
}
