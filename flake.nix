{
  description = "Finix — y0usaf's finix-only systems (host wiring in modules/finix/default.nix, shared builder in modules/finix/finixSystem.nix); the historical NixOS tree lives on the nixos-legacy branch";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nh = {
      url = "github:nix-community/nh";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rush = {
      url = "github:rockorager/rush";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    manzil = {
      url = "github:y0usaf/manzil";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    bolo = {
      # Private repo: ssh fetcher (same as phi).
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

    # DeepSeek Harness: the dsh package + web app, built from the local
    # sandbox flake. Consumed by the dsh-web finit service (hosts/
    # y0usaf-desktop/finix/dsh-web.nix) as an always-on tailnet web server.
    deepseek-harness = {
      url = "path:/home/y0usaf/dev/sandbox/deepseek-harness-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    phi = {
      url = "git+ssh://git@github.com/y0usaf/phi.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fx = {
      url = "github:y0usaf/fx/add-nix-flake";
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

    oh-my-pi = {
      # omp coding agent upstream flake (exposes packages.<system>.omp).
      url = "github:can1357/oh-my-pi";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    reasonix-flake = {
      url = "github:y0usaf/reasonix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fx-flake = {
      url = "github:y0usaf/fx-flake?ref=add-nix-flake";
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

    paseo = {
      url = "github:getpaseo/paseo";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hermes-agent = {
      # Pin upstream source directly; desktop's mutable Electron headers hash is
      # corrected where that package is materialized. Never depend on a sibling
      # checkout: clean clones and rescue hosts must evaluate this flake alone.
      url = "github:NousResearch/hermes-agent/fcbd1076a93841fa88855acce810e342a5b78101";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    aphrodite-hermes = {
      # Aphrodite CCR compression plugin for the Hermes gateway
      # (github:PlayForm/Aphrodite-Hermes). Source-only: the repo has no
      # flake.nix, so we consume it as a plain tree (like deno2nix).
      # The prebuilt binary + dylib it normally auto-downloads are pinned
      # separately (hash-verified vs. the release SHA256SUMS) in
      # hosts/y0usaf-server/finix/hermes.nix — no runtime downloads on NixOS.
      url = "github:PlayForm/Aphrodite-Hermes";
      flake = false;
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

    nix-on-droid = {
      url = "github:nix-community/nix-on-droid";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Finit-based OS: the server's installed OS since 2026-07-15 (NixOS is
    # its on-disk rescue entry). See modules/finix/default.nix (host wiring),
    # modules/finix/finixSystem.nix (shared builder) + modules/finix/NOTES.md.
    finix.url = "github:finix-community/finix";
  };

  outputs = inputs: let
    system = "x86_64-linux";
    cfg = import ./modules/finix {inherit inputs system;};
  in {
    nixosConfigurations =
      cfg.hosts
      // {
        # Finix is the installed server system; retain the hostname alias for
        # tools that only inspect nixosConfigurations.
        y0usaf-server-finix = cfg.hosts.y0usaf-server;
      };

    nixOnDroidConfigurations = {
      default = inputs."nix-on-droid".lib.nixOnDroidConfiguration {
        pkgs = import inputs.nixpkgs {
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

    finixConfigurations = cfg.hosts;

    packages."${system}" = cfg.packages;

    formatter."${system}" = inputs.nixpkgs.legacyPackages."${system}".alejandra;
  };
}
