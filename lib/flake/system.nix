###############################################################################
# System Configuration Utilities
# Functions for generating NixOS system configurations
###############################################################################
{
  lib,
  pkgs,
  helpers,
  hostsDir ? ../../hosts,
}: let
  shared = import ./shared.nix {inherit lib pkgs helpers hostsDir;};
  hjem = import ./hjem.nix {inherit lib pkgs helpers hostsDir;};
in {
  # Helper function to generate nixosConfigurations
  mkNixosConfigurations = {
    inputs,
    system,
    commonSpecialArgs,
  }:
    shared.mapToAttrs
    (hostname: {
      name = hostname;
      value = inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs =
          shared.mkSpecialArgs commonSpecialArgs hostname
          // {
            inherit hostname;
            inherit hostsDir;
          };
        modules =
          [
            # Import hardware configuration directly from the unified host directory
            (hostsDir + "/${hostname}/hardware-configuration.nix")
            # Import the shared configurations
            (hostsDir + "/default.nix")
            ../../system
            (shared.mkSharedModule {inherit hostname hostsDir;})

            inputs.hjem.nixosModules.default
            # Add system-specific imports that shouldn't be exposed to HM
          ]
          ++ (shared.systemConfigs.${hostname}.cfg.system.imports or [])
          ++ [
            # Apply system configuration
            ({config, ...}: {
              networking.hostName = config.cfg.shared.hostname;
              time.timeZone = config.cfg.shared.timezone;
              system.stateVersion = config.cfg.shared.stateVersion;

              # Apply users configuration
              inherit (shared.systemConfigs.${hostname}) users;

              # Hardware configuration
              hardware = {
                bluetooth.enable = shared.systemConfigs.${hostname}.cfg.system.hardware.bluetooth.enable or false;
              };
            })

            # Configure hjem
            (hjem.mkHjemNixosModule {
              inherit inputs hostname;
              inherit commonSpecialArgs;
            })
            inputs.chaotic.nixosModules.default
          ];
      };
    })
    shared.hostNames;
}
