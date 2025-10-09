{
  inputs,
  system,
  nixpkgsConfig,
}: let
  # Create sources compatibility layer for overlays
  # Map flake inputs to the old sources.* pattern
  sources = {
    Fast-Fonts = inputs.fast-fonts;
    "Deepin-Dark-hyprcursor" = inputs.deepin-dark-hyprcursor;
    "Deepin-Dark-xcursor" = inputs.deepin-dark-xcursor;
    neovim-nightly-overlay = inputs.neovim-nightly-overlay;
    obs-backgroundremoval = inputs.obs-backgroundremoval;
    obs-image-reaction = inputs.obs-image-reaction;
    obs-pipewire-audio-capture = inputs.obs-pipewire-audio-capture;
    obs-vkcapture = inputs.obs-vkcapture;
  };

  # Direct overlays import
  overlays = import ./overlays sources;

  # Direct pkgs with overlays
  pkgs = import inputs.nixpkgs {
    inherit system overlays;
    config = nixpkgsConfig;
  };

  inherit (pkgs) lib;

  # Custom generators library
  genLib = import ./generators lib;

  # Host configs
  hostConfigs = {
    y0usaf-desktop = import ../configs/hosts/y0usaf-desktop {inherit pkgs lib;};
    y0usaf-laptop = import ../configs/hosts/y0usaf-laptop {inherit pkgs lib;};
    y0usaf-server = import ../configs/hosts/y0usaf-server {inherit pkgs lib;};
  };
in {
  nixosConfigurations = lib.mapAttrs (_hostName: hostConfig:
    import (inputs.nixpkgs + "/nixos") {
      inherit system;
      configuration = {
        imports = [
          # Host system configuration
          (_:
            (removeAttrs hostConfig ["imports" "homeDirectory"])
            // {
              inherit (hostConfig) imports;
              user = {
                name = "y0usaf";
                inherit (hostConfig) homeDirectory;
              };
              nixpkgs = {
                inherit overlays;
                config = nixpkgsConfig;
              };
            })
          # Disko
          (inputs.disko + "/module.nix")
          # Determinate Nix
          inputs.determinate.nixosModules.default
          # Hjem
          ({...}: {
            imports = [
              (_: {
                _module.args.hjem-lib = import (inputs.hjem + "/lib.nix") {inherit lib pkgs;};
              })
              (inputs.hjem + "/modules/nixos")
            ];
            config.hjem = {
              linker = pkgs.callPackage (inputs.smfh + "/package.nix") {};
              users = {};
            };
          })
          ./user-config.nix
          ../modules/user
        ];
        _module.args = {
          inherit hostConfig lib genLib;
          # Pass inputs for modules that might need them
          flakeInputs = inputs;
          # Legacy compatibility
          sources = sources;
          disko = inputs.disko;
        };
      };
    })
  hostConfigs;
}
