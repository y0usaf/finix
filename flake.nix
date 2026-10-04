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
      url = "github:y0usaf/oh-my-fx/e4fa282cc3f533bb91f02fcd4defab6ac8ec6755";
      inputs.nixpkgs.follows = "nixpkgs";
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

    deno2nix = {
      url = "github:aMOPel/deno2nix?ref=custom-made-fetcher";
      flake = false;
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

    strictix = {
      url = "github:y0usaf/strictix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-on-droid = {
      url = "github:nix-community/nix-on-droid";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    finix.url = "github:finix-community/finix";
  };

  outputs = inputs: import ./modules/outputs.nix inputs;
}
