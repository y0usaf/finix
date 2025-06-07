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

  # Extract user settings
  getUserSettings = cfg:
    lib.filterAttrs (name: _: !(builtins.elem name globalSettings)) cfg;
in {
  # Flake outputs
  flakeOutputs = {};

  # Helper function to create hjem configurations
  mkHjemConfigurations = {commonSpecialArgs, ...}:
    shared.mapToAttrs
    (hostname: {
      name = "${shared.unifiedConfigs.${hostname}.cfg.shared.username}@${hostname}";
      value = {
        specialArgs =
          shared.mkSpecialArgs commonSpecialArgs hostname
          // {
            inherit hostname;
            hostsDir = ../../hosts;
          };
        modules = [
          ../../hjem
          (shared.mkSharedModule {
            inherit hostname;
            hostsDir = ../../hosts;
          })
          {
            # Apply global settings directly from cfg.hjem
            clobberFiles = shared.hjemConfigs.${hostname}.cfg.hjem.clobberFiles or false;

            # Apply all non-global settings to hjem.users.<username>
            imports = [
              {
                hjem.users.${shared.unifiedConfigs.${hostname}.cfg.shared.username} = lib.mkMerge [
                  # Apply hjem settings
                  (getUserSettings (shared.hjemConfigs.${hostname}.cfg.hjem or {}))
                  # Apply hjome settings directly (extract hjome without cfg wrapper)
                  (shared.unifiedConfigs.${hostname}.cfg.hjome or {})
                ];
              }
            ];
          }
        ];
      };
    })
    shared.hostNames;
}
