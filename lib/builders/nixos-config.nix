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
          ../../modules/home
        ];
        _module.args = {
          inherit hostname users sources inputs;
          lib = pkgs.lib;
          hostConfig = hostConfig;
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
