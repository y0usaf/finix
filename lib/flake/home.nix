{
  lib,
  pkgs,
  hostsDir ? ../../system/hosts,
  homeHostsDir ? ../../home/hosts,
}: let
  shared = import ./shared.nix { inherit lib pkgs hostsDir homeHostsDir; };
in {
  inherit (shared) hostNames systemConfigs homeConfigs;
  
  # Helper function to generate homeConfigurations
  mkHomeConfigurations = {
    inputs,
    pkgs,
    commonSpecialArgs,
  }: let
    # Check if system configs have the expected structure
    validHostNames =
      builtins.filter (
        hostname:
          builtins.hasAttr hostname shared.systemConfigs
          && builtins.hasAttr "cfg" shared.systemConfigs.${hostname}
          && builtins.hasAttr "system" shared.systemConfigs.${hostname}.cfg
          && builtins.hasAttr "username" shared.systemConfigs.${hostname}.cfg.system
      )
      shared.hostNames;
  in
    builtins.listToAttrs (
      map
      (hostname: let
        systemConfig = shared.systemConfigs.${hostname};
        homeConfig = shared.homeConfigs.${hostname};
      in {
        name = systemConfig.cfg.system.username;
        value = inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = commonSpecialArgs // {
            hostSystem = systemConfig;
            hostHome = homeConfig;
          };
          modules = [../../home/home.nix];
        };
      })
      validHostNames # Use only valid hosts
    );
}