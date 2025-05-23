###############################################################################
# Home Manager Configuration Utilities
# Functions for generating Home Manager configurations
###############################################################################
{
  lib,
  pkgs,
  hostsDir ? ../../system/hosts,
  homeHostsDir ? ../../home/hosts,
}: let
  shared = import ./shared.nix {inherit lib pkgs hostsDir homeHostsDir;};
in {
  # Helper function to generate homeConfigurations
  mkHomeConfigurations = {
    inputs,
    pkgs,
    commonSpecialArgs,
  }:
    shared.mapToAttrs
    (hostname: {
      name = shared.systemConfigs.${hostname}.cfg.system.username;
      value = inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = shared.mkSpecialArgs commonSpecialArgs hostname;
        modules = [../../home/home.nix];
      };
    })
    shared.validHostNames;
}
