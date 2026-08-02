{
  description = "Finix — y0usaf's finix-only systems; the historical NixOS tree lives on the nixos-legacy branch";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nh = {
      url = "github:nix-community/nh";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    manzil = {
      url = "github:y0usaf/manzil";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    bolo = {
      # Private repo: ssh fetcher (same as phi / nvflashk-linux).
      url = "git+ssh://git@github.com/y0usaf/bolo.git";
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

    # Official Anthropic .deb (downloads.claude.ai apt pool) repackaged with
    # autoPatchelfHook. We consume nix/claude-desktop.nix via callPackage
    # against our own pkgs (same pattern as codex-desktop-linux), so the
    # flake's own nixpkgs instance is never evaluated.
    claude-desktop-linux = {
      url = "github:aaddrick/claude-desktop-debian";
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
      # Vendored patch of github:NousResearch/hermes-agent@2b0fb72 — upstream's
      # electron-headers FOD sha went stale when artifacts.electronjs.org
      # recompressed the v41.9.1 tarball (see finix-vendor/hermes-agent commit).
      # Refresh: repeat the same one-line sha256 bump when the mirror rebuilds.
      url = "git+file:///home/y0usaf/finix-vendor/hermes-agent";
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
    # its on-disk rescue entry). See finix/ (default.nix + NOTES.md).
    finix.url = "github:finix-community/finix";
  };

  outputs = {nixpkgs, ...} @ inputs: let
    system = "x86_64-linux";
    inherit (nixpkgs) lib;

    # Finix: main is finix-only. The desktop's packages/dotfiles reach
    # finix directly through finix/compat-import.nix.
    finixStaging = import ./finix {inherit inputs system;};
  in {
    nixosConfigurations = {
      # Desktop default = finix: bare `nh os switch` on the desktop targets
      # finix (via finix's nixos-compat: config.system.build.toplevel).
      y0usaf-desktop = finixStaging.desktopPersistent;

      # Finix is the installed server system; retain the hostname alias for
      # tools that only inspect nixosConfigurations.
      y0usaf-server = finixStaging.serverPersistent;
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
    # modules in ./modules/* (their own tree lives in ./finix and is
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
