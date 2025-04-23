{
  lib, 
  pkgs,
  hostsDir ? ../../system/hosts,
  homeHostsDir ? ../../home/hosts,
}: let
  # Get all valid host names (excluding special directories and files)
  hostNames = builtins.filter (
    name:
      name
      != "README.md"
      && name != "default.nix"
      && builtins.pathExists (hostsDir + "/${name}/default.nix")
      && builtins.pathExists (homeHostsDir + "/${name}/default.nix")
  ) (builtins.attrNames (builtins.readDir hostsDir));

  # Import system configurations for each host
  systemConfigs = builtins.listToAttrs (
    map
    (name: {
      inherit name;
      value = import (hostsDir + "/${name}/default.nix") {inherit lib pkgs;};
    })
    hostNames
  );

  # Import home configurations for each host
  homeConfigs = builtins.listToAttrs (
    map
    (name: {
      inherit name;
      value = import (homeHostsDir + "/${name}/default.nix") {inherit lib pkgs;};
    })
    hostNames
  );
in {
  inherit hostNames systemConfigs homeConfigs;

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
          builtins.hasAttr hostname systemConfigs
          && builtins.hasAttr "cfg" systemConfigs.${hostname}
          && builtins.hasAttr "system" systemConfigs.${hostname}.cfg
          && builtins.hasAttr "username" systemConfigs.${hostname}.cfg.system
      )
      hostNames;
  in
    builtins.listToAttrs (
      map
      (hostname: let
        systemConfig = systemConfigs.${hostname};
        homeConfig = homeConfigs.${hostname};
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