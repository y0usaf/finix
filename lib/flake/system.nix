###############################################################################
# System Configuration Utilities
# Functions for generating NixOS system configurations
###############################################################################
{
  lib,
  pkgs,
  hostsDir ? ../../hosts,
}: let
  shared = import ./shared.nix {
    inherit lib pkgs hostsDir;
    inputs = null;
  };
in {
  # Helper function to generate nixosConfigurations
  mkNixosConfigurations = {
    inputs,
    system,
    commonSpecialArgs,
  }: let
    sharedWithInputs = import ./shared.nix {inherit lib pkgs hostsDir inputs;};
    maidIntegration = import ./maid.nix {inherit hostsDir;};
  in
    builtins.listToAttrs (map
      (hostname: {
        name = hostname;
        value = inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs =
            sharedWithInputs.mkSpecialArgs commonSpecialArgs hostname
            // {
              inherit hostname;
              inherit hostsDir;
              lib = pkgs.lib;  # Use the extended lib with our overlay
            };
          modules =
            [
              # Core system modules
              (sharedWithInputs.mkSharedModule {inherit hostname hostsDir;})

              # Integration modules - each handles its own setup
              (maidIntegration.mkNixosModule {inherit inputs hostname;})

              # Home modules (maid-based)
              ../../home

              # External modules
              inputs.chaotic.nixosModules.default
            ]
            ++ (sharedWithInputs.systemConfigs.${hostname}.system.imports or [])
            ++ [
              # Apply core system configuration
              ({config, ...}: {
                networking.hostName = config.shared.hostname;
                time.timeZone = config.shared.timezone;
                system.stateVersion = config.shared.stateVersion;

                # Apply users configuration
                inherit (sharedWithInputs.systemConfigs.${hostname}) users;

                # Note: Hardware configuration is available via hostSystem.hardware for hardware modules
              })
            ];
        };
      })
      sharedWithInputs.hostNames);
}
