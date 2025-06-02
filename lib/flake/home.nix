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
      name = "${shared.unifiedConfigs.${hostname}.cfg.shared.username}@${hostname}";
      value = inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = shared.mkSpecialArgs commonSpecialArgs hostname;
        modules = [
          ../../home
          (../../lib/shared/core.nix)
          {
            home = {
              inherit (shared.unifiedConfigs.${hostname}.cfg.shared) username homeDirectory stateVersion;
            };
            # Apply unified home configuration with shared config
            cfg = shared.homeConfigs.${hostname}.cfg // {
              inherit (shared.unifiedConfigs.${hostname}.cfg) shared;
            };
          }
        ];
      };
    })
    shared.hostNames;
}
