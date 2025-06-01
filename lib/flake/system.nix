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
  hjem = import ./hjem.nix {inherit lib pkgs helpers;};
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
        specialArgs = shared.mkSpecialArgs commonSpecialArgs hostname;
        modules =
          [
            # Import hardware configuration directly from the unified host directory
            (hostsDir + "/${hostname}/hardware-configuration.nix")
            # Import the shared configurations
            (hostsDir + "/default.nix")
            inputs.home-manager.nixosModules.home-manager
            inputs.hjem.nixosModules.default
            # Add system-specific imports that shouldn't be exposed to HM
          ]
          ++ (shared.systemConfigs.${hostname}.cfg.system.imports or [])
          ++ [
            # Apply system configuration from hostSystem
            {
              networking.hostName = shared.systemConfigs.${hostname}.cfg.system.hostname;
              time.timeZone = shared.systemConfigs.${hostname}.cfg.system.timezone;
              system.stateVersion = shared.systemConfigs.${hostname}.cfg.system.stateVersion;

              # Apply users configuration
              inherit (shared.systemConfigs.${hostname}) users;

              # Hardware configuration
              hardware = {
                bluetooth.enable = shared.systemConfigs.${hostname}.cfg.hardware.bluetooth.enable or false;
              };
            }
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                extraSpecialArgs = shared.mkSpecialArgs commonSpecialArgs hostname;
                users.${shared.systemConfigs.${hostname}.cfg.system.username} = {
                  imports = [../../home];
                  home = {
                    inherit (shared.systemConfigs.${hostname}.cfg.system) stateVersion;
                    homeDirectory = inputs.nixpkgs.lib.mkForce shared.systemConfigs.${hostname}.cfg.system.homeDirectory;
                  };
                  # Apply unified home configuration
                  inherit (shared.homeConfigs.${hostname}) cfg;
                };
              };
            }
            # Apply hjem configuration if it exists
            {
              hjem = {
                users.${shared.systemConfigs.${hostname}.cfg.system.username} =
                  lib.mkIf (shared.hjemConfigs ? ${hostname})
                  (hjem.processHjemConfig shared.hjemConfigs.${hostname}.cfg);
              };
            }
            inputs.chaotic.nixosModules.default
          ];
      };
    })
    shared.hostNames;
}
