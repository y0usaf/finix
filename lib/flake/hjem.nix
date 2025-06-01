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

  # Known global Hjem settings
  globalSettings = ["clobberFiles"];

  # Extract global settings
  getGlobalSettings = cfg:
    lib.filterAttrs (name: _: builtins.elem name globalSettings) cfg;

  # Extract user settings
  getUserSettings = cfg:
    lib.filterAttrs (name: _: !(builtins.elem name globalSettings)) cfg;
in {
  # Flake outputs
  flakeOutputs = {};

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
            # Apply global settings directly from cfg.hjem
            clobberFiles = shared.hjemConfigs.${hostname}.cfg.hjem.clobberFiles or false;

            # Apply all non-global settings to hjem.users.<username>
            imports = [
              {
                hjem.users.${shared.systemConfigs.${hostname}.cfg.system.username} = lib.mkMerge [
                  # Apply hjem settings
                  (getUserSettings (shared.hjemConfigs.${hostname}.cfg.hjem or {}))
                  # Apply hjome settings directly
                  (shared.hjemConfigs.${hostname}.cfg.hjome or {})
                ];
              }
            ];
          }
        ];
      };
    })
    shared.hostNames;
}
