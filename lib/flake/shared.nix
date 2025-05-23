###############################################################################
# Shared Flake Utilities
# Common functionality for discovering and importing host configurations
###############################################################################
{
  lib,
  pkgs,
  hostsDir ? ../../system/hosts,
  homeHostsDir ? ../../home/hosts,
}: let
  # Get all valid host names (excluding special directories and files)
  hostNames = builtins.filter (
    name:
      name
      != "README.md"
      && name != "default.nix"
      && builtins.pathExists (hostsDir + "/${name}/default.nix")
      && builtins.pathExists (homeHostsDir + "/${name}/default.nix")
  ) (builtins.attrNames (builtins.readDir hostsDir));

  # Import system configurations for each host
  systemConfigs = builtins.listToAttrs (
    map
    (name: {
      inherit name;
      value = import (hostsDir + "/${name}/default.nix") {inherit lib pkgs;};
    })
    hostNames
  );

  # Import home configurations for each host
  homeConfigs = builtins.listToAttrs (
    map
    (name: {
      inherit name;
      value = import (homeHostsDir + "/${name}/default.nix") {inherit lib pkgs;};
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
