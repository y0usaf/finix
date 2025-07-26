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

  # Direct user configs import
  userConfigs = {
    y0usaf = import ../configs/users/y0usaf {inherit pkgs;};
    guest = import ../configs/users/guest {inherit pkgs;};
  };

  # Host config
  hostConfig = import ../configs/hosts/y0usaf-desktop {inherit pkgs;};
  inherit (hostConfig) users;
  hostUserConfigs = pkgs.lib.genAttrs users (username: userConfigs.${username});

  # Create the lib that will be exported with proper overlay application
  lib = pkgs.lib;
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
          hostSystem = {
            inherit (hostConfig) users;
            inherit (hostConfig) hostname;
            inherit (hostConfig) homeDirectory;
            inherit (hostConfig) stateVersion;
            inherit (hostConfig) timezone;
            profile = hostConfig.profile or "default";
            hardware = hostConfig.hardware or {};
            services = hostConfig.services or {};
          };
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
        # User home configurations via maid
        ({
          config,
          lib,
          ...
        }: {
          imports = [
            (import (sources.nix-maid + "/src/nixos") {
              smfh = null;
            })
          ];
          config = {
            # Use proper NixOS module merging
            home = lib.mkMerge (
              lib.mapAttrsToList (
                _username: userConfig:
                # Remove system-specific config that doesn't belong in home
                  lib.filterAttrs (name: _: name != "system") userConfig
              )
              hostUserConfigs
            );
            # Configure maid for each user
            users.users = lib.genAttrs users (_username: {
              maid = {
                packages = [];
              };
            });
          };
        })
        # Import user configuration abstraction
        ./user-config.nix
        # Import home manager
        ../modules/home
      ];
      _module.args = {
        inherit (hostConfig) hostname;
        inherit users sources;
        lib = lib;
        inherit hostConfig;
        userConfigs = hostUserConfigs;
        hostSystem = hostConfig;
        hostsDir = ../configs/hosts;
        # Direct access to commonly used sources
        inherit (sources) disko nix-minecraft Fast-Font;
      };
    };
  };
}
