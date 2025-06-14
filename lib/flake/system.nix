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
  shared = import ./shared.nix {inherit lib pkgs helpers hostsDir; inputs = null;};
in {
  # Helper function to generate nixosConfigurations
  mkNixosConfigurations = {
    inputs,
    system,
    commonSpecialArgs,
  }: let
    sharedWithInputs = import ./shared.nix {inherit lib pkgs helpers hostsDir inputs;};
    hjemIntegration = import ./hjem.nix {inherit lib pkgs helpers hostsDir inputs;};
    maidIntegration = import ./maid.nix {inherit lib pkgs helpers hostsDir inputs;};
  in
    sharedWithInputs.mapToAttrs
    (hostname: {
      name = hostname;
      value = inputs.nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs =
          sharedWithInputs.mkSpecialArgs commonSpecialArgs hostname
          // {
            inherit hostname;
            inherit hostsDir;
          };
        modules =
          [
            # Core system modules
            (hostsDir + "/${hostname}/hardware-configuration.nix")
            (hostsDir + "/default.nix")
            ../../system
            (sharedWithInputs.mkSharedModule {inherit hostname hostsDir;})
            
            # Integration modules - each handles its own setup
            (hjemIntegration.mkNixosModule {inherit inputs hostname commonSpecialArgs;})
            (maidIntegration.mkNixosModule {inherit inputs hostname commonSpecialArgs;})
            
            # Home modules (maid-based)
            ../../home
            
            # External modules
            inputs.chaotic.nixosModules.default
          ]
          ++ (sharedWithInputs.systemConfigs.${hostname}.cfg.system.imports or [])
          ++ [
            # Apply core system configuration
            ({config, ...}: {
              networking.hostName = config.cfg.shared.hostname;
              time.timeZone = config.cfg.shared.timezone;
              system.stateVersion = config.cfg.shared.stateVersion;

              # Apply users configuration
              inherit (sharedWithInputs.systemConfigs.${hostname}) users;

              # Hardware configuration
              hardware = {
                bluetooth.enable = sharedWithInputs.systemConfigs.${hostname}.cfg.system.hardware.bluetooth.enable or false;
              };
            })
          ];
      };
    })
    sharedWithInputs.hostNames;
}
