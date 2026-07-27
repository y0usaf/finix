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

    phi = {
      url = "git+ssh://git@github.com/y0usaf/phi.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Follow pi-flake main; flake.lock records resolved revision.
    pi-flake = {
      url = "github:y0usaf/pi-flake?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pi-harness = {
      url = "git+ssh://git@github.com/y0usaf/pi-harness.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    linear-cli = {
      url = "github:y0usaf/linear-cli?ref=nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # deno2nix is linear-cli's build tooling (linear-cli flake imports it as
    # flake=false). We vendor it here too so we can rebuild the `linear`
    # package locally with a corrected deno-deps hash, instead of forking
    # the dead linear-cli wrapper repo to fix its stale FOD hash. Pinned to
    # the same ref linear-cli uses.
    deno2nix = {
      url = "github:aMOPel/deno2nix?ref=custom-made-fetcher";
      flake = false;
    };

    # Source-only (flake = false): we callPackage discord's package files from
    # this snapshot against current pkgs instead of importing a second nixpkgs.
    nixpkgs-discord-legacy = {
      url = "github:NixOS/nixpkgs/2fc6539b481e1d2569f25f8799236694180c0993";
      flake = false;
    };

    rudo = {
      url = "github:y0usaf/rudo";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ekko = {
      url = "github:y0usaf/ekko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
    };

    # moonshell is no longer a separate input: it merged into tomoe as
    # its in-process shell subsystem (tomoe FUSION.md; the standalone
    # repo is archived).
    tomoe = {
      url = "github:y0usaf/tomoe";
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

    nvflashk-linux = {
      url = "git+ssh://git@github.com/y0usaf/nvflashk-linux.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-on-droid = {
      url = "github:nix-community/nix-on-droid";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Finit-based OS: the server's installed OS since 2026-07-15 (NixOS is
    # its on-disk rescue entry). See modules/finix/ (default.nix + NOTES.md).
    finix.url = "github:finix-community/finix";
  };

  outputs = {nixpkgs, ...} @ inputs: let
    system = "x86_64-linux";
    inherit (nixpkgs) lib;

    finixStaging = import ./modules/finix {inherit inputs system;};

    mkHost = {
      domains,
      extraModules ? [],
      hostDir,
    }:
      lib.nixosSystem {
        inherit system;
        specialArgs = {
          flakeInputs = inputs;
          inherit finixStaging;
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
            ]
            ++ extraModules
          );
      };
  in {
    nixosConfigurations = {
      # Desktop default = finix: bare `nh os switch` on the desktop targets
      # finix (via finix's nixos-compat: config.system.build.toplevel).
      # NixOS stays as the on-disk rescue entry under -nixos (only run
      # `nh os switch -H y0usaf-desktop-nixos` while booted into NixOS).
      y0usaf-desktop = finixStaging.desktopPersistent;
      y0usaf-desktop-nixos = mkHost {
        hostDir = ./hosts/y0usaf-desktop;
        domains = ["core" "desktop" "shell" "tools" "user-services" "dev" "gaming"];
      };

      # Desktop + VBIOS maintenance specialisation. Evaluating the
      # specialisation re-runs the whole module system (~20-30% eval time),
      # so it lives in a variant instead of the default host:
      #   nh os switch -H y0usaf-desktop-vbios
      y0usaf-desktop-vbios = mkHost {
        hostDir = ./hosts/y0usaf-desktop;
        domains = ["core" "desktop" "shell" "tools" "user-services" "dev" "gaming"];
        extraModules = [./hosts/y0usaf-desktop-vbios/vbios-maintenance.nix];
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

      # Finix alias so `nh os switch -H <name>` resolves it: nh only reads
      # nixosConfigurations (hostname-keyed), never finixConfigurations.
      y0usaf-server-finix = finixStaging.serverPersistent;
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

    # Finix systems, first-class beside nixosConfigurations. Same module
    # universe split as always: finix systems can never import the NixOS
    # modules in ./modules/* (their own tree lives in ./modules/finix and is
    # never in mkHost's domain map, so NixOS never imports it back either).
    finixConfigurations = {
      y0usaf-server = finixStaging.serverPersistent;
      y0usaf-desktop = finixStaging.desktopPersistent;
    };

    packages."${system}" = {
      finix-server-persistent-deploy = finixStaging.persistentDeployPackage;
      finix-server-boot = finixStaging.bootPackage;

      finix-desktop-deploy = finixStaging.desktopDeployPackage;
    };

    formatter."${system}" = nixpkgs.legacyPackages."${system}".alejandra;
  };
}
