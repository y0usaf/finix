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
        specialArgs = shared.mkSpecialArgs commonSpecialArgs hostname // {
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
(shared.mkSharedModule { inherit hostname hostsDir; })
            inputs.home-manager.nixosModules.home-manager
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
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                extraSpecialArgs = shared.mkSpecialArgs commonSpecialArgs hostname // {
                  inherit hostname;
                  inherit hostsDir;
                };
                users.${shared.unifiedConfigs.${hostname}.cfg.shared.username} = {
                  imports = [../../home (shared.mkSharedModule { inherit hostname hostsDir; })];
                  home = {
                    inherit (shared.unifiedConfigs.${hostname}.cfg.shared) stateVersion;
                    homeDirectory = lib.mkForce shared.unifiedConfigs.${hostname}.cfg.shared.homeDirectory;
                  };
                  # Apply unified home configuration
                  inherit (shared.homeConfigs.${hostname}) cfg;
                };
              };
            }
            # Apply hjem configuration if it exists
            {
              # Add the alias from hjome to hjem.users.username
              imports = [
                (lib.mkAliasOptionModule ["hjome"] ["hjem" "users" shared.unifiedConfigs.${hostname}.cfg.shared.username])
              ];

              # Configure hjem for this user
              hjem = {
                specialArgs = shared.mkSpecialArgs commonSpecialArgs hostname // {
                  inherit hostname;
                  inherit hostsDir;
                };
                users.${shared.unifiedConfigs.${hostname}.cfg.shared.username} = lib.mkMerge [
                  {
                    imports = [../../hjem (shared.mkSharedModule { inherit hostname hostsDir; })];
                  }
                  {
                    cfg.hjome = shared.hjemConfigs.${hostname}.cfg.hjome or {};
                  }
                ];
              };
            }
            inputs.chaotic.nixosModules.default
          ];
      };
    })
    shared.hostNames;
}
