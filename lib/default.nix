let
  sources = import ../npins;
  system = "x86_64-linux";

  # Direct overlays import
  overlays = import ./overlays sources;

  # Direct pkgs with overlays
  pkgs = import sources.nixpkgs {
    inherit system;
    inherit overlays;
    config = {
      allowUnfree = true;
      cudaSupport = true;
    };
  };

  # Host config - system-level configuration only
  hostConfig = import ../configs/hosts/y0usaf-desktop {inherit pkgs;};

  # User configs - home folder management only (separate from host)
  userConfigs = {
    y0usaf = import ../configs/users/y0usaf {inherit pkgs;};
    guest = import ../configs/users/guest {inherit pkgs;};
  };

  # Create the lib that will be exported with proper overlay application
  inherit (pkgs) lib;
in {
  inherit lib;
  formatter.${system} = pkgs.alejandra;

  nixosConfigurations.y0usaf-desktop = import (sources.nixpkgs + "/nixos") {
    inherit system;
    configuration = {
      imports = [
        # Host system configuration
        ({config, ...}: {
          inherit (hostConfig) imports;
          # Set user configuration from primary user
          user = let
            primaryUser = builtins.head hostConfig.users;
          in {
            name = primaryUser;
            inherit (hostConfig) homeDirectory;
          };
          # Configure nixpkgs with overlays
          nixpkgs = {
            inherit overlays;
            config = {
              allowUnfree = true;
              cudaSupport = true;
            };
          };
        })
        # User home configurations via hjem
        ({
          config,
          lib,
          ...
        }: {
          imports = [
            # Use hjem for home management
            (sources.hjem + "/modules/nixos")
          ];
          config = {
            # Use proper NixOS module merging for all user configs
            home = lib.mkMerge (
              lib.mapAttrsToList (
                _username: userConfig:
                # Remove system-specific config that doesn't belong in home
                  lib.filterAttrs (name: _: name != "system") userConfig
              )
              userConfigs
            );
            # Configure hjem for each user (independent of host)
            hjem = {
              # Use SMFH manifest linker instead of systemd-tmpfiles
              linker = pkgs.callPackage (sources.smfh + "/package.nix") {};
              users =
                lib.mapAttrs (_username: _userConfig: {
                  packages = [];
                  files = {};
                })
                userConfigs;
            };
          };
        })
        # Import user configuration abstraction
        ./user-config.nix
        # Import home manager
        ../modules/home
      ];
      _module.args = {
        inherit hostConfig userConfigs sources;
        inherit (pkgs) lib;
        # Direct access to commonly used sources
        inherit (sources) disko nix-minecraft Fast-Font;
      };
    };
  };
}
