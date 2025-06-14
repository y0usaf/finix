###############################################################################
# Hjem Configuration Utilities
# Functions for generating hjem configurations
###############################################################################
{
  lib,
  pkgs,
  helpers,
  hostsDir ? ../../hosts,
  inputs ? null,
}: let
  shared = import ./shared.nix {inherit lib pkgs helpers hostsDir inputs;};

  # Known global Hjem settings
  globalSettings = [];

  # Extract user settings
  getUserSettings = cfg:
    lib.filterAttrs (name: _: !(builtins.elem name globalSettings)) cfg;
in {
  # Flake outputs
  flakeOutputs = {};

  # Complete NixOS module for hjem integration
  mkNixosModule = {
    inputs,
    hostname,
    commonSpecialArgs,
  }: {
    imports = [
      inputs.hjem.nixosModules.default
      (lib.mkAliasOptionModule ["hjome"] ["hjem" "users" shared.unifiedConfigs.${hostname}.cfg.shared.username])
    ];

    hjem = {
      clobberByDefault = true;
      linker = inputs.smfh.packages.${pkgs.system}.default;
      specialArgs =
        shared.mkSpecialArgs commonSpecialArgs hostname
        // {
          inherit hostname;
          inherit hostsDir;
        };
      users.${shared.unifiedConfigs.${hostname}.cfg.shared.username} = {
        imports = [../../hjem (shared.mkSharedModule {inherit hostname hostsDir;})];
        cfg.hjome = shared.hjemConfigs.${hostname}.cfg.hjome or {};
      };
    };
  };

  # Helper function to create standalone hjem configurations
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
