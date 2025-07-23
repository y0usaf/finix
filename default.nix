let
  # Import npins sources
  sources = import ./npins;

  system = "x86_64-linux";

  # Import nixpkgs first to get lib with nixosSystem
  nixpkgs = import sources.nixpkgs {inherit system;};

  # Consolidated overlays function
  mkOverlays = sources: [
    # Extended lib overlay with helper functions
    (import ./lib/overlays/lib-extensions.nix)
    # Neovim nightly overlay
    (import sources.neovim-nightly-overlay)
    # Fast fonts overlay
    (final: _prev: {
      fastFonts = final.stdenvNoCC.mkDerivation {
        pname = "fast-fonts";
        version = "1.0.0";
        src = sources.Fast-Font;

        installPhase = ''
          mkdir -p $out/share/fonts/truetype
          install -m444 -Dt $out/share/fonts/truetype *.ttf
          mkdir -p $out/share/doc/fast-fonts
          if [ -f LICENSE ]; then
            install -m444 -Dt $out/share/doc/fast-fonts LICENSE
          fi
          if [ -f README.md ]; then
            install -m444 -Dt $out/share/doc/fast-fonts README.md
          fi
        '';

        meta = with final.lib; {
          description = "Fast Font Collection - TTF fonts";
          longDescription = "Fast Font Collection provides optimized monospace and sans-serif fonts";
          homepage = "https://github.com/y0usaf/Fast-Font";
          platforms = platforms.all;
          license = licenses.mit;
        };
      };
    })
  ];

  # Import nixpkgs with overlays for pkgs
  pkgs = import sources.nixpkgs {
    inherit system;
    overlays = mkOverlays sources;
    config.allowUnfree = true;
    config.cudaSupport = true;
  };

  # Import user configurations
  userConfigs = {
    y0usaf = import ./users/y0usaf/default.nix {
      pkgs = pkgs;
      inputs = inputs;
    };
    guest = import ./users/guest/default.nix {
      pkgs = pkgs;
      inputs = inputs;
    };
  };

  # Build NixOS configurations directly
  mkNixosConfigurations = {
    inputs,
    system,
    commonSpecialArgs,
  }: let
    hostNames = ["y0usaf-desktop"];
    overlays = import ./lib/overlays sources;

    mkHostConfig = hostname: let
      hostConfig = import (./hosts + "/${hostname}/default.nix") {
        inherit pkgs inputs;
      };
      users = hostConfig.users;
      hostUserConfigs = pkgs.lib.genAttrs users (username: userConfigs.${username});
    in {
      name = hostname;
      value = import (sources.nixpkgs + "/nixos") {
        inherit system;
        configuration = {
          imports = [
            # Host system configuration
            ({config, ...}: {
              imports = hostConfig.imports;
              hostSystem = {
                users = hostConfig.users;
                hostname = hostConfig.hostname;
                homeDirectory = hostConfig.homeDirectory;
                stateVersion = hostConfig.stateVersion;
                timezone = hostConfig.timezone;
                profile = hostConfig.profile or "default";
                hardware = hostConfig.hardware or {};
                services = hostConfig.services or {};
              };
              # Configure nixpkgs with overlays
              nixpkgs.overlays = overlays;
              nixpkgs.config.allowUnfree = true;
              nixpkgs.config.cudaSupport = true;
            })
            # User home configurations via maid
            ({
              config,
              pkgs,
              lib,
              ...
            }: {
              imports = [
                (import (sources.nix-maid + "/src/nixos") {
                  smfh = null; # We'll handle smfh differently
                })
              ];
              config = {
                # Use proper NixOS module merging instead of manual attribute manipulation
                home = lib.mkMerge (
                  lib.mapAttrsToList (
                    username: userConfig:
                    # Remove system-specific config that doesn't belong in home
                      lib.filterAttrs (name: _: name != "system") userConfig
                  )
                  hostUserConfigs
                );
                # Configure maid for each user
                users.users = lib.genAttrs users (username: {
                  maid = {
                    packages = [];
                  };
                });
              };
            })
            # Import home manager
            ./home
          ];
          _module.args =
            commonSpecialArgs
            // {
              inherit hostname users;
              lib = pkgs.lib;
              hostConfig = hostConfig;
              userConfigs = hostUserConfigs;
              hostSystem = hostConfig;
              hostsDir = ./hosts;
            };
        };
      };
    };
  in
    builtins.listToAttrs (map mkHostConfig hostNames);

  # Pass sources directly instead of fake flake inputs
  # Keep minimal inputs structure only for compatibility with modules that expect it
  inputs = {
    nixpkgs = sources.nixpkgs;
    disko = sources.disko;
    nix-maid = sources.nix-maid;
  };

  # Use npins system utilities directly

  # Common special args for all hosts
  commonSpecialArgs = {
    inherit sources inputs;
    # Direct access to commonly used sources
    inherit (sources) disko nix-minecraft Fast-Font;
  };
in {
  # Formatter
  formatter.${system} = pkgs.alejandra;

  # NixOS configurations
  nixosConfigurations = mkNixosConfigurations {
    inherit inputs system commonSpecialArgs;
  };
}
