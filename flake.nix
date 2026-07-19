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

    phi = {
      url = "git+ssh://git@github.com/y0usaf/phi.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Follow pi-flake main; flake.lock records resolved revision.
    pi-flake = {
      url = "github:y0usaf/pi-flake?ref=main";
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

    gpui-shell = {
      url = "github:andre-brandao/gpui-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    moonshell = {
      url = "git+ssh://git@github.com/y0usaf/moonshell.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
    # its on-disk rescue entry). See ./finix + finix/NOTES.md.
    finix.url = "github:finix-community/finix";
  };

  outputs = {nixpkgs, ...} @ inputs: let
    system = "x86_64-linux";
    inherit (nixpkgs) lib;

    finixStaging = import ./finix {inherit inputs system;};

    mkHost = {
      domains,
      hostDir,
      extraModules ? [],
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
      y0usaf-desktop = mkHost {
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
    # universe split as always: finix systems can never import ./modules/*.
    finixConfigurations = {
      y0usaf-server = finixStaging.serverPersistent;
      y0usaf-desktop = finixStaging.desktopPersistent;
    };

    packages."${system}" = {
      finix-server-persistent = finixStaging.persistentPackage;
      finix-server-persistent-deploy = finixStaging.persistentDeployPackage;
      finix-server-boot = finixStaging.bootPackage;
      # Desktop (phase 1: console skeleton; drives its own ESP via `local`):
      finix-desktop-persistent = finixStaging.desktopPersistentPackage;
      finix-desktop-boot = finixStaging.desktopBootPackage;
      finix-desktop-deploy = finixStaging.desktopDeployPackage;
      # Attic (retired kexec era; see finix/attic/):
      finix-server-vm = finixStaging.vmPackage;
      finix-server-trial = finixStaging.trialPackage;
      finix-server-persistent-kexec = finixStaging.persistentKexecPackage;
    };

    formatter."${system}" = nixpkgs.legacyPackages."${system}".alejandra;
  };
}
