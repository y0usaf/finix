{
  description = "y0usaf's NixOS configuration";

  inputs = {
    # Pin to same revision as npins had
    nixpkgs.url = "github:NixOS/nixpkgs/7df7ff7d8e00218376575f0acdcc5d66741351ee";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    smfh = {
      url = "github:feel-co/smfh";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    obs-backgroundremoval = {
      url = "github:royshil/obs-backgroundremoval";
      flake = false;
    };

    obs-image-reaction = {
      url = "github:L-Nafaryus/obs-image-reaction";
      flake = false;
    };

    obs-pipewire-audio-capture = {
      url = "github:dimtpap/obs-pipewire-audio-capture";
      flake = false;
    };

    obs-vkcapture = {
      url = "github:nowrep/obs-vkcapture";
      flake = false;
    };

    deepin-dark-hyprcursor = {
      url = "github:y0usaf/Deepin-Dark-hyprcursor";
      flake = false;
    };

    deepin-dark-xcursor = {
      url = "github:y0usaf/Deepin-Dark-xcursor";
      flake = false;
    };

    fast-fonts = {
      url = "github:y0usaf/Fast-Fonts";
      flake = false;
    };

    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/0.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    system = "x86_64-linux";

    # Centralized nixpkgs config
    nixpkgsConfig = {
      allowUnfree = true;
      cudaSupport = true;
      permittedInsecurePackages = [
        "qtwebengine-5.15.19"
      ];
    };

    # Import lib with flake inputs
    lib = import ./lib {
      inherit inputs system nixpkgsConfig;
    };
  in {
    inherit (lib) nixosConfigurations;

    # Expose for easier access
    formatter.${system} = nixpkgs.legacyPackages.${system}.alejandra;
  };
}
