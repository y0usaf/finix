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

    ash = {
      # Private repo: ssh fetcher (same as bolo). The SBCL "Agent Shell".
      # `github:` cannot resolve it: the anonymous API returns 404, which
      # fails `nix flake update` even though the locked rev stays fetchable.
      url = "git+ssh://git@github.com/y0usaf/ash.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    cudaterm.url = "github:y0usaf/cudaterm";

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
      # Pinned: the 2026-09-03 upstream merge (fd3e3019) dropped flake.nix,
      # so a branch-tracking input cannot resolve ("flake.nix does not
      # exist") and `nix flake update` aborts before writing the lock. This
      # is the last flake-bearing revision; unpin once the fork ships a
      # flake again, or replace the input with a local Zig build.
      url = "github:y0usaf/oh-my-fx/e4fa282cc3f533bb91f02fcd4defab6ac8ec6755";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Follow pi-flake main; flake.lock records resolved revision.
    pi-flake = {
      url = "github:y0usaf/pi-flake?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pi-harness = {
      # amux workspace; Finix consumes only its pi-harness package.
      url = "git+ssh://git@github.com/y0usaf/amux.git?ref=main";
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

    # Keep upstream's nixpkgs pin: its SBCL and generated Lisp package set
    # must be updated together. Use the CLINEDI pin fix until upstream includes it.
    autolith.url = "github:y0usaf/autolith?ref=fix-clinedi-pin";

    # Emeraldian TUI (Obsidian vault terminal UI). Pinned to the PR head
    # until upstream merges iamrohithrnair/emeraldian#25; keep the upstream
    # flake's tested nixpkgs pin (same autolith reasoning).
    emeraldian.url = "github:y0usaf/emeraldian/4557d20ce664a12dec7d5acf3d76a467cf4972a4";

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
      # Desktop defaults; overflow panes hide and components keep durable state.
      url = "github:y0usaf/ekko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    paseo = {
      url = "github:getpaseo/paseo";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # `line`: the SBCL agent harness that Hermes' slope-line plugin dispatches to.
    # `path:` like hermes-desktop-terminal, because the checkout is under active
    # development and a git input cannot be locked while its tree is dirty
    # ("has an unlocked input"). Re-run `nix flake lock --update-input slope`
    # after editing slope; switch to git+file:// once its work is committed.
    slope = {
      url = "path:/home/y0usaf/dev/developing/slope";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hermes-bots-mod = {
      url = "github:y0usaf/hermes-bots-mod/41b505132dc77f256faea85e2d36519f93238427";
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

    # The compositor, from this checkout. git+file keeps the copy to the
    # committed tree (no 4 GB target/, no .git), and its own nixpkgs pin
    # supplies the wlroots 0.20.1 the native ABI was built against, so it must
    # not follow this flake's nixpkgs.
    #
    # Pinned by rev like tomoe-lua: a ref-tracking git+file input cannot be
    # locked while this checkout is dirty, and `nix flake update` then refuses
    # to write the lock for the whole flake ("has an unlocked input"). Bump
    # after committing: `git -C ~/dev/maintaining/tomoe rev-parse HEAD` and
    # replace the rev below.
    tomoe.url = "git+file:///home/y0usaf/dev/maintaining/tomoe?rev=2ab42d0ebc1cea3166bb4de2b48923c20a8867d6&shallow=1";

    # Fallback compositor: the last Rust+Lua-era revision of the same
    # checkout, before the Lisp rewrite. `shallow=1` is required — the local
    # clone is shallow, and a bare ?rev= URL is rejected ("shallow
    # repositories are only allowed when 'shallow = true;' is specified").
    # No nixpkgs.follows: this rev's build was verified against its own
    # nixpkgs pin (e52c192be9d7b2c4bd4aed326c8731b35f8bb75c); following ours
    # would move it onto an unverified build path.
    tomoe-lua.url = "git+file:///home/y0usaf/dev/maintaining/tomoe?rev=ae0cd20d92dd00f1694745e1b2af3da05ca0e103&shallow=1";

    strictix = {
      url = "github:y0usaf/strictix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-on-droid = {
      url = "github:nix-community/nix-on-droid";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
