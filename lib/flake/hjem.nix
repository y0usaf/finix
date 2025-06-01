###############################################################################
# Hjem Configuration Utilities
# Functions for generating hjem configurations
###############################################################################
{
  lib,
  pkgs,
  helpers,
  hostsDir ? ../../hosts,
}: let
  shared = import ./shared.nix {inherit lib pkgs helpers hostsDir;};
in {
  # Flake outputs
  flakeOutputs = { };

  # Helper function to create hjem configurations
  mkHjemConfigurations = {
    inputs,
    commonSpecialArgs,
  }:
    shared.mapToAttrs
    (hostname: {
      name = "${shared.systemConfigs.${hostname}.cfg.system.username}@${hostname}";
      value = {
        specialArgs = shared.mkSpecialArgs commonSpecialArgs hostname;
        modules = [
          ../../hjem
          {
            # Common options that apply to all hjem users
            clobberFiles = shared.hjemConfigs.${hostname}.cfg.hjem.clobberFiles or false;
            
            # This module provides the alias from hjome -> hjem.users.username 
            # which is used in the host configuration
            imports = [
              (lib.mkAliasOptionModule ["hjome"] ["hjem" "users" shared.systemConfigs.${hostname}.cfg.system.username])
            ];
          }
        ];
      };
    })
    shared.hostNames;
}