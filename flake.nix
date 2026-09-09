{
  description = "Finix systems for y0usaf";

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

    cudaterm.url = "github:y0usaf/cudaterm/dbc572cf3160b3ca1014d8066206b275a0669939";

    monstar = {
      # Wayland terminal emulator built on libghostty (CPU rendered, like
      # foot). Used on the AMD Framework.
      url = "github:rockorager/monstar";
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

    grok-bot = {
      # Private repo: ssh fetcher (same as bolo). Unfree redistributed
      # Anysphere/XAI artifacts, kept private.
      url = "git+ssh://git@github.com/y0usaf/grok-bot-0.18-linux.git";
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

    phi = {
      url = "git+ssh://git@github.com/y0usaf/phi.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    oh-my-fx = {
      url = "github:y0usaf/oh-my-fx";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Follow pi-flake main; flake.lock records resolved revision.
    pi-flake = {
      url = "github:y0usaf/pi-flake?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pi-harness = {
      # Unified amux workspace exposes both pi-harness and omp-harness
      # packages from one repo (replaces the old pi-harness/omp-harness
      # repos).
      url = "git+ssh://git@github.com/y0usaf/amux.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    oh-my-pi = {
      # omp coding agent upstream flake (exposes packages.<system>.omp).
      url = "github:can1357/oh-my-pi";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    omp-harness = {
      # Same amux workspace as pi-harness; exposes
      # packages.<system>.omp-harness and apps.<system>.default.
      url = "git+ssh://git@github.com/y0usaf/amux.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    reasonix-flake = {
      url = "github:y0usaf/reasonix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Keep upstream's nixpkgs pin: its SBCL and generated Lisp package set
    # must be updated together.
    autolith.url = "github:lambda-symbolics/autolith";

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
      # Desktop defaults: taskbar, window controls, menus, floating and snapping.
      url = "github:y0usaf/ekko/7edc36049cc16de3881029d86912199aedbaf18c";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    paseo = {
      url = "github:getpaseo/paseo";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hermes-bots-mod = {
      url = "github:y0usaf/hermes-bots-mod";
      flake = false;
    };

    hermes-desktop-terminal = {
      url = "path:/home/y0usaf/dev/sandbox/hermes-desktop-terminal";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hermes-agent = {
      # Track upstream main; the flake.lock rev is the actual pin. Earlier inline
      # rev pin (v2026.8.19) left the install ~1800 commits behind, missing the
      # deleted-profile-resurrection fixes (#94842/#95188/#94426).
      url = "github:NousResearch/hermes-agent/main";
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

    # Installs the ARM native bridge required by ARM-only Android apps such as
    # TFT in the x86_64 Waydroid container.
    waydroidscript = {
      url = "github:casualsnek/waydroid_script";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Disposable Zellij-profile preview; implementation lives in its Ekko module.
    ekko-zellij-preview.url = "git+file:///home/y0usaf/dev/maintaining/ekko-zellij-parity?ref=zellij-parity-01a076eb&rev=a9a129c6ee99a4b725b9cdf465726c763ece7e17";

    # Finit-based OS and module system.
    finix.url = "github:finix-community/finix";
  };

  # All output construction lives under modules/.
  outputs = inputs:
    (inputs.nixpkgs.lib.evalModules {
      specialArgs = {
        inherit inputs;
        system = "x86_64-linux";
      };
      modules = [./modules/outputs.nix];
    }).config.flake;
}
