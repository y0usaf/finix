###############################################################################
# System Configuration Utilities
# Functions for generating NixOS system configurations without shared dependencies
###############################################################################
{
  lib,
  pkgs,
  hostsDir ? ../../hosts,
}: {
  # Helper function to generate nixosConfigurations
  mkNixosConfigurations = {
    inputs,
    system,
    commonSpecialArgs,
  }: let
    hostNames = ["y0usaf-desktop"];

    maidIntegration = import ./maid.nix {inherit hostsDir;};
  in
    builtins.listToAttrs (map
      (hostname: let
        # Import host configuration
        hostConfig = import (hostsDir + "/${hostname}/default.nix") {
          inherit pkgs inputs;
        };
      in {
        name = hostname;
        value = inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs =
            commonSpecialArgs
            // {
              inherit hostname hostsDir;
              inherit (pkgs) lib;
              # Make host configuration available to modules
              hostConfig = hostConfig;
              # Pass hostSystem for hardware modules (for backward compatibility)
              hostSystem = hostConfig.system;
            };
          modules = [
            # System configuration with direct values (no shared dependency)
            ({config, ...}: {
              # Import system modules from host config
              imports = hostConfig.system.imports;

              # Configure system options directly from host config
              hostSystem = {
                username = hostConfig.system.username;
                hostname = hostConfig.system.hostname;
                homeDirectory = hostConfig.system.homeDirectory;
                stateVersion = hostConfig.system.stateVersion;
                timezone = hostConfig.system.timezone;
                profile = hostConfig.system.profile or "default";
                hardware = hostConfig.system.hardware or {};
                services = hostConfig.system.services or {};
              };
            })

            # Integration modules
            (maidIntegration.mkNixosModule {inherit inputs hostname;})

            # Home modules (maid-based)
            ../../home

            # External modules
            inputs.chaotic.nixosModules.default
          ];
        };
      })
      hostNames);
}
