{
  description = "y0usaf's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nh = {
      url = "github:nix-community/nh";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    manzil = {
      url = "github:y0usaf/Manzil";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fonts = {
      url = "github:y0usaf/fonts";
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

    concord = {
      url = "github:chojs23/concord";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    linear-cli = {
      url = "github:y0usaf/linear-cli?ref=nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-discord-legacy.url = "github:NixOS/nixpkgs/2fc6539b481e1d2569f25f8799236694180c0993";

    pi-flake = {
      url = "github:y0usaf/pi-rlm/rlm-rewrite-1779064714";
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

    nur = {
      url = "path:/home/y0usaf/Dev/nur";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      # PR 3508: open-consume-into-column window rule.
      url = "github:niri-wm/niri?ref=pull/3508/head";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    shojiwm = {
      url = "github:bea4dev/ShojiWM";
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

    nvtune = {
      url = "github:y0usaf/nvtune";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-on-droid = {
      url = "github:nix-community/nix-on-droid";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {nixpkgs, ...} @ inputs: let
    system = "x86_64-linux";
    inherit (nixpkgs) lib;

    mkHost = {
      domains,
      hostDir,
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
              hostDir
              inputs.shojiwm.nixosModules.default
            ]
          );
      };
  in {
    nixosConfigurations = {
      y0usaf-desktop = mkHost {
        hostDir = ./hosts/y0usaf-desktop;
        domains = ["core" "desktop" "shell" "tools" "user-services" "dev" "gaming"];
      };

      y0usaf-laptop = mkHost {
        hostDir = ./hosts/y0usaf-laptop;
        domains = ["core" "desktop" "shell" "tools" "user-services" "dev" "gaming"];
      };

      y0usaf-framework = mkHost {
        hostDir = ./hosts/y0usaf-framework;
        domains = ["core" "desktop" "shell" "tools" "user-services" "dev" "gaming"];
      };

      y0usaf-server = mkHost {
        hostDir = ./hosts/y0usaf-server;
        domains = ["core" "shell" "tools" "user-services" "dev"];
      };
    };

    nixOnDroidConfigurations = {
      default = inputs."nix-on-droid".lib.nixOnDroidConfiguration {
        pkgs = import nixpkgs {
          system = "aarch64-linux";
        };
        extraSpecialArgs = {
          flakeInputs = inputs;
        };
        modules = [
          ./hosts/android-phone/nix-on-droid.nix
        ];
      };
    };

    formatter."${system}" = nixpkgs.legacyPackages."${system}".alejandra;
  };
}
