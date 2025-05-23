###############################################################################
# System Configuration Utilities
# Functions for generating NixOS system configurations
###############################################################################
{
  lib,
  pkgs,
  hostsDir ? ../../system/hosts,
  homeHostsDir ? ../../home/hosts,
}: let
  shared = import ./shared.nix {inherit lib pkgs hostsDir homeHostsDir;};
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
        modules = [
          # Import hardware configuration directly from the host directory
          (hostsDir + "/${hostname}/hardware-configuration.nix")
          # Import the shared configurations
          (hostsDir + "/default.nix")
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = shared.mkSpecialArgs commonSpecialArgs hostname;
              users.${shared.systemConfigs.${hostname}.cfg.system.username} = {
                imports = [../../home/home.nix];
                home = {
                  stateVersion = shared.systemConfigs.${hostname}.cfg.system.stateVersion;
                  homeDirectory = inputs.nixpkgs.lib.mkForce shared.systemConfigs.${hostname}.cfg.system.homeDirectory;
                };
              };
            };
          }
          inputs.chaotic.nixosModules.default
        ];
      };
    })
    shared.hostNames;
}
