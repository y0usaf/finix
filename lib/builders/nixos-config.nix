{
  sources,
  pkgs,
  system,
  inputs,
  userConfigs,
}: let
  overlays = import ../overlays sources;

  mkHostConfig = hostname: let
    hostConfig = import (../../configs/hosts + "/${hostname}/default.nix") {
      inherit pkgs inputs;
    };
    inherit (hostConfig) users;
    hostUserConfigs = pkgs.lib.genAttrs users (username: userConfigs.${username});
  in {
    name = hostname;
    value = import (sources.nixpkgs + "/nixos") {
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
                smfh = null; # We'll handle smfh differently
              })
            ];
            config = {
              # Use proper NixOS module merging instead of manual attribute manipulation
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
          ../user-config.nix
          # Import home manager
          ../../modules/home
        ];
        _module.args = {
          inherit hostname users sources inputs;
          inherit (pkgs) lib;
          inherit hostConfig;
          userConfigs = hostUserConfigs;
          hostSystem = hostConfig;
          hostsDir = ../../configs/hosts;
          # Direct access to commonly used sources
          inherit (sources) disko nix-minecraft Fast-Font;
        };
      };
    };
  };
in
  hostNames: builtins.listToAttrs (map mkHostConfig hostNames)
