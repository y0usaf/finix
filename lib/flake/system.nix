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
        specialArgs = shared.mkSpecialArgs commonSpecialArgs hostname;
        modules =
          [
            # Import hardware configuration directly from the unified host directory
            (hostsDir + "/${hostname}/hardware-configuration.nix")
            # Import the shared configurations
            (hostsDir + "/default.nix")
            ../../system
            (../../lib/shared/core.nix)
            inputs.home-manager.nixosModules.home-manager
            inputs.hjem.nixosModules.default
            # Add system-specific imports that shouldn't be exposed to HM
          ]
          ++ (shared.systemConfigs.${hostname}.cfg.system.imports or [])
          ++ [
            # Apply system configuration from cfg.shared
            ({ config, ... }: {
              # Apply shared configuration to the shared core module
              cfg.shared = shared.unifiedConfigs.${hostname}.cfg.shared;
              
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
                extraSpecialArgs = shared.mkSpecialArgs commonSpecialArgs hostname;
                users.${shared.unifiedConfigs.${hostname}.cfg.shared.username} = {
                  imports = [../../home (../../lib/shared/core.nix)];
                  home = {
                    inherit (shared.unifiedConfigs.${hostname}.cfg.shared) stateVersion;
                    homeDirectory = inputs.nixpkgs.lib.mkForce shared.unifiedConfigs.${hostname}.cfg.shared.homeDirectory;
                  };
                  # Apply unified home configuration with shared config
                  cfg = shared.homeConfigs.${hostname}.cfg // {
                    shared = shared.unifiedConfigs.${hostname}.cfg.shared;
                  };
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
                specialArgs = shared.mkSpecialArgs commonSpecialArgs hostname;
                users.${shared.unifiedConfigs.${hostname}.cfg.shared.username} = lib.mkMerge [
                  {
                    imports = [../../hjem];
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
