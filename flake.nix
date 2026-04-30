{
  description = "y0usaf's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    bayt = {
      url = "github:y0usaf/bayt?ref=feat/shared-core-standalone-phase4";
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
    };

    mango = {
      url = "github:DreamMaoMao/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    handy = {
      url = "github:cjpais/Handy/c1e11faa71f010436d4ff63b3467f8d6973ecba8";
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

    linear-cli = {
      url = "github:y0usaf/linear-cli?ref=nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-discord-legacy.url = "github:NixOS/nixpkgs/2fc6539b481e1d2569f25f8799236694180c0993";

    pi-flake = {
      url = "github:y0usaf/pi-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zjstatus-hints = {
      url = "github:y0usaf/zjstatus-hints?ref=feat/custom-labels";
    };

    rudo = {
      url = "github:y0usaf/rudo";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agent-slack = {
      url = "github:stablyai/agent-slack";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
    };

    gpui-shell = {
      url = "github:andre-brandao/gpui-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:niri-wm/niri";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    strictix = {
      url = "github:y0usaf/strictix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    patchix = {
      url = "github:y0usaf/patchix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agent-harness = {
      url = "git+ssh://git@github.com/y0usaf/Agent-Harness";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvtune = {
      url = "github:y0usaf/nvtune";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {nixpkgs, ...} @ inputs: let
    system = "x86_64-linux";
    inherit (nixpkgs) lib;

    mkHost = {
      domains,
      hostDir,
      profileDir,
    }:
      lib.nixosSystem {
        inherit system;
        specialArgs = {
          flakeInputs = inputs;
        };
        modules =
          (import ./recursivelyImport.nix {
            inherit (lib) hasSuffix;
            inherit (lib.filesystem) listFilesRecursive;
          }) (
            lib.concatMap (domain:
              {
                core = [./modules/core];
                desktop = [./modules/desktop];
                shell = [./modules/shell];
                tools = [./modules/tools];
                user-services = [./modules/user-services];
                dev = [./modules/dev];
                gaming = [./modules/gaming];
              }."${domain}")
            domains
            ++ [
              profileDir
              hostDir
            ]
          );
      };
  in {
    nixosConfigurations = {
      y0usaf-desktop = mkHost {
        hostDir = ./hosts/y0usaf-desktop;
        profileDir = ./modules/profiles/y0usaf;
        domains = ["core" "desktop" "shell" "tools" "user-services" "dev" "gaming"];
      };

      y0usaf-laptop = mkHost {
        hostDir = ./hosts/y0usaf-laptop;
        profileDir = ./modules/profiles/y0usaf;
        domains = ["core" "desktop" "shell" "tools" "user-services" "dev" "gaming"];
      };

      y0usaf-framework = mkHost {
        hostDir = ./hosts/y0usaf-framework;
        profileDir = ./modules/profiles/y0usaf-dev;
        domains = ["core" "desktop" "shell" "tools" "user-services" "dev" "gaming"];
      };

      y0usaf-server = mkHost {
        hostDir = ./hosts/y0usaf-server;
        profileDir = ./modules/profiles/server;
        domains = ["core" "shell" "tools" "user-services" "dev"];
      };
    };

    formatter."${system}" = nixpkgs.legacyPackages."${system}".alejandra;
  };
}
