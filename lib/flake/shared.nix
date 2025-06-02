###############################################################################
# Shared Flake Utilities
# Common functionality for discovering and importing unified host configurations
###############################################################################
{
  lib,
  pkgs,
  helpers,
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
          # Move hardware to top level for system modules
          inherit (unifiedConfigs.${name}.cfg.system) hardware;
          system = {
            # Move imports into system scope to avoid HM exposure
            imports = unifiedConfigs.${name}.imports or [];
            inherit (unifiedConfigs.${name}.cfg.system) hardware;
          };
          inherit (unifiedConfigs.${name}.cfg) core;
        };
        users = unifiedConfigs.${name}.users or {};
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
        cfg =
          unifiedConfigs.${name}.cfg.home
          // {
            # Include shared core config in home as well
            inherit (unifiedConfigs.${name}.cfg) core;
          };
      };
    })
    hostNames
  );

  # Extract hjem configurations from unified configs
  hjemConfigs = builtins.listToAttrs (
    map
    (name: {
      inherit name;
      value = {
        cfg = {
          hjome = unifiedConfigs.${name}.cfg.hjome or {};
        };
      };
    })
    hostNames
  );

  # Get valid host names with proper config structure
  validHostNames =
    builtins.filter (
      hostname:
        builtins.hasAttr hostname unifiedConfigs
        && builtins.hasAttr "cfg" unifiedConfigs.${hostname}
        && builtins.hasAttr "shared" unifiedConfigs.${hostname}.cfg
        && builtins.hasAttr "username" unifiedConfigs.${hostname}.cfg.shared
    )
    hostNames;

  # Common specialArgs builder
  mkSpecialArgs = commonSpecialArgs: hostname:
    commonSpecialArgs
    // {
      hostSystem = systemConfigs.${hostname};
      hostHome = homeConfigs.${hostname};
      hostHjem = hjemConfigs.${hostname};
      inherit helpers;
    };

  # Generic listToAttrs + map helper
  mapToAttrs = f: list: builtins.listToAttrs (map f list);
in {
  inherit hostNames unifiedConfigs systemConfigs homeConfigs hjemConfigs validHostNames mkSpecialArgs mapToAttrs;
}
