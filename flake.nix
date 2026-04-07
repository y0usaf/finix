{
  description = "y0usaf's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    nixpkgs-discord-legacy.url = "github:NixOS/nixpkgs/2fc6539b481e1d2569f25f8799236694180c0993";

    pi-mono = {
      url = "github:y0usaf/pi-mono";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rudo = {
      url = "github:y0usaf/rudo";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pi-agents = {
      url = "git+file:/home/y0usaf/Dev/pi-mono/packages/pi-agents";
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
    legacyPkgs = nixpkgs.legacyPackages;
  in {
    nixosConfigurations = import ./hosts.nix {inherit inputs;};

    formatter."${system}" = legacyPkgs."${system}".alejandra;
  };
}
