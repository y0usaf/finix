###############################################################################
# Home Manager Configuration Utilities
# Functions for generating home-manager configurations
###############################################################################
{
  lib,
  pkgs,
  helpers,
  hostsDir ? ../../hosts,
}: let
  shared = import ./shared.nix {inherit lib pkgs helpers hostsDir;};
in {
  # Helper function to generate homeConfigurations
  mkHomeConfigurations = {
    inputs,
    pkgs,
    commonSpecialArgs,
  }:
    shared.mapToAttrs
    (hostname: {
      name = "${shared.systemConfigs.${hostname}.cfg.system.username}@${hostname}";
      value = inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = shared.mkSpecialArgs commonSpecialArgs hostname;
        modules = [
          ../../home
          {
            home = {
              inherit (shared.systemConfigs.${hostname}.cfg.system) username homeDirectory stateVersion;
            };
          }
        ];
      };
    })
    shared.hostNames;
}
