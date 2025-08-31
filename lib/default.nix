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

  # Host configs - system-level configuration only
  hostConfigs = {
    y0usaf-desktop = import ../configs/hosts/y0usaf-desktop {inherit pkgs lib;};
    y0usaf-laptop = import ../configs/hosts/y0usaf-laptop/system.nix {inherit pkgs lib;};
  };

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

  nixosConfigurations = lib.mapAttrs (hostName: hostConfig:
    import (sources.nixpkgs + "/nixos") {
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
          # Direct user configurations - hardcoded imports
          (_: {
            users = lib.mkMerge [
              (userConfigs.y0usaf.users or {})
              (userConfigs.guest.users or {})
            ];
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
              # Hardcoded home configs (excluding users.users)
              home = lib.mkMerge [
                (lib.filterAttrs (name: _: name != "users") userConfigs.y0usaf)
                (lib.filterAttrs (name: _: name != "users") userConfigs.guest)
              ];
              # Configure hjem for each user (independent of host)
              hjem = {
                # Use SMFH manifest linker instead of systemd-tmpfiles
                linker = pkgs.callPackage (sources.smfh + "/package.nix") {};
                users = {
                  y0usaf = {
                    packages = [];
                    files = {};
                  };
                  guest = {
                    packages = [];
                    files = {};
                  };
                };
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
    })
  hostConfigs;
}
