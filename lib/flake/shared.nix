###############################################################################
# Shared Flake Utilities
# Common functionality for discovering and importing unified host configurations
###############################################################################
{
  lib,
  pkgs,
  hostsDir ? ../../hosts,
}: let
  # Get all valid host names (excluding special directories and files)
  hostNames = builtins.filter (
    name:
      name
      != "README.md"
      && name != "default.nix"
      && builtins.pathExists (hostsDir + "/${name}/default.nix")
  ) (builtins.attrNames (builtins.readDir hostsDir));

  # Import unified configurations for each host
  unifiedConfigs = builtins.listToAttrs (
    map
    (name: {
      inherit name;
      value = import (hostsDir + "/${name}/default.nix") {inherit lib pkgs;};
    })
    hostNames
  );

  # Extract system configurations from unified configs
  systemConfigs = builtins.listToAttrs (
    map
    (name: {
      inherit name;
      value = {
        cfg = {
          system = unifiedConfigs.${name}.cfg.system;
          hardware = unifiedConfigs.${name}.cfg.system.hardware;
          core = unifiedConfigs.${name}.cfg.core;
        };
        users = unifiedConfigs.${name}.users or {};
        imports = unifiedConfigs.${name}.imports or [];
      };
    })
    hostNames
  );

  # Extract home configurations from unified configs
  homeConfigs = builtins.listToAttrs (
    map
    (name: {
      inherit name;
      value = {
        cfg = unifiedConfigs.${name}.cfg.home // {
          # Include shared core config in home as well
          core = unifiedConfigs.${name}.cfg.core;
        };
      };
    })
    hostNames
  );

  # Get valid host names with proper system config structure
  validHostNames =
    builtins.filter (
      hostname:
        builtins.hasAttr hostname systemConfigs
        && builtins.hasAttr "cfg" systemConfigs.${hostname}
        && builtins.hasAttr "system" systemConfigs.${hostname}.cfg
        && builtins.hasAttr "username" systemConfigs.${hostname}.cfg.system
    )
    hostNames;

  # Common specialArgs builder
  mkSpecialArgs = commonSpecialArgs: hostname:
    commonSpecialArgs
    // {
      hostSystem = systemConfigs.${hostname};
      hostHome = homeConfigs.${hostname};
    };

  # Generic listToAttrs + map helper
  mapToAttrs = f: list: builtins.listToAttrs (map f list);
in {
  inherit hostNames systemConfigs homeConfigs validHostNames mkSpecialArgs mapToAttrs;
}