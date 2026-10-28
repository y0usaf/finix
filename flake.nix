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
      url = "git+ssh://git@github.com/y0usaf/ash.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    cudaterm.url = "github:y0usaf/cudaterm";

    monstar = {
      url = "github:rockorager/monstar";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    manzil = {
      url = "github:y0usaf/manzil";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    bolo = {
      url = "git+ssh://git@github.com/y0usaf/bolo.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    grok-bot = {
      url = "git+ssh://git@github.com/y0usaf/silva-bot.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    silva.url = "git+ssh://git@github.com/y0usaf/silva.git";

    boar-rs = {
      url = "git+file:///home/y0usaf/dev/developing/boar-rs?rev=e1d9432ef5f9ab280bf8019da7f7471393541c17";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    crest = {
      url = "git+ssh://git@github.com/sylvarant-ai/crest.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    iets = {
      url = "github:numtide/iets";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nacre = {
      url = "git+ssh://git@github.com/y0usaf/nacre.git";
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

    obs-twitch-tts = {
      url = "github:y0usaf/obs-twitch-tts";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-code-nix = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-desktop-linux = {
      url = "github:aaddrick/claude-desktop-debian";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    leverage = {
      url = "git+ssh://git@github.com/y0usaf/leverage-linux.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    glide-browser = {
      url = "github:glide-browser/glide.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    phi = {
      url = "git+ssh://git@github.com/y0usaf/phi.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    oh-my-fx = {
      url = "github:y0usaf/oh-my-fx/8ea7aa8df1c82c915b6ea1d918f10a945e79b01d";
    };

    pi = {
      url = "github:earendil-works/pi/v1.0.2";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-darwin-x64.follows = "nixpkgs";
    };

    pi-chronobreak = {
      url = "github:y0usaf/pi-chronobreak";
      flake = false;
    };

    pi-rlm = {
      url = "github:y0usaf/pi-rlm";
      flake = false;
    };

    pi-recap = {
      url = "github:y0usaf/pi-recap";
      flake = false;
    };

    pi-accounts = {
      url = "github:y0usaf/pi-accounts";
      flake = false;
    };

    pi-ampersand = {
      url = "github:y0usaf/pi-ampersand";
      flake = false;
    };

    pi-donsetch = {
      url = "github:y0usaf/pi-donsetch";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    durapi = {
      url = "github:y0usaf/durapi";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pi.follows = "pi";
      inputs.pi-donsetch.follows = "pi-donsetch";
    };

    pi-harness = {
      url = "git+ssh://git@github.com/y0usaf/amux.git?ref=main";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pi.follows = "pi";
    };

    oh-my-pi.url = "github:can1357/oh-my-pi";

    autolith.url = "github:y0usaf/autolith?ref=fix-clinedi-pin";

    emeraldian.url = "github:y0usaf/emeraldian/4557d20ce664a12dec7d5acf3d76a467cf4972a4";

    linear-cli = {
      url = "github:y0usaf/linear-cli?ref=nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    tomoe.url = "github:y0usaf/tomoe";

    mado.url = "git+ssh://git@github.com/y0usaf/mado.git";

    frame-charge.url = "github:y0usaf/frame-charge";

    strictix = {
      url = "github:y0usaf/strictix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-on-droid = {
      url = "github:nix-community/nix-on-droid";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    finix.url = "github:finix-community/finix";

    nixpkgs-librewolf.url = "github:NixOS/nixpkgs/56c02bc00adcf003215cc4bd996d6efaf4cff188";
  };

  outputs = inputs: import ./modules/outputs.nix inputs;
}
