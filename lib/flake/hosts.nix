{
  lib,
  pkgs,
  hostsDir ? ../../system/hosts,
}: let
  # Get all valid host names (excluding special directories and files)
  hostNames = builtins.filter (
    name:
      name
      != "README.md"
      && name != "default.nix"
      && builtins.pathExists (hostsDir + "/${name}/default.nix")
  ) (builtins.attrNames (builtins.readDir hostsDir));

  # Import all available hosts dynamically, merging system and home configs
  hosts = builtins.listToAttrs (
    map
    (name: {
      inherit name;
      value = let
        systemCfg = import (hostsDir + "/${name}/default.nix") {inherit lib pkgs;};
        homeCfg = import (../../home/hosts/${name}/default.nix) {inherit lib pkgs;};
      in
        lib.recursiveUpdate systemCfg homeCfg;
    })
    hostNames
  );
in {
  inherit hostNames hosts;

  # Helper function to generate nixosConfigurations
  mkNixosConfigurations = {
    inputs,
    system,
    commonSpecialArgs,
  }:
    builtins.listToAttrs (
      map
      (hostname: {
        name = hostname;
        value = inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = commonSpecialArgs // {host = hosts.${hostname};};
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
                extraSpecialArgs = commonSpecialArgs // {host = hosts.${hostname};};
                users.${hosts.${hostname}.cfg.system.username} = {
                  imports = [../../home/home.nix];
                  home = {
                    stateVersion = hosts.${hostname}.cfg.system.stateVersion;
                    homeDirectory = inputs.nixpkgs.lib.mkForce hosts.${hostname}.cfg.system.homeDirectory;
                  };
                };
              };
            }
            inputs.chaotic.nixosModules.default
          ];
        };
      })
      hostNames
    );

  # Helper function to generate homeConfigurations
  mkHomeConfigurations = {
    inputs,
    pkgs,
    commonSpecialArgs,
  }: let
    # Debug: Check if hosts have the expected structure
    validHostNames =
      builtins.filter (
        hostname:
          builtins.hasAttr hostname hosts
          && builtins.hasAttr "cfg" hosts.${hostname}
          && builtins.hasAttr "system" hosts.${hostname}.cfg
          && builtins.hasAttr "username" hosts.${hostname}.cfg.system
      )
      hostNames;
  in
    builtins.listToAttrs (
      map
      (hostname: let
        hostConfig = hosts.${hostname};
      in {
        name = hostConfig.cfg.system.username;
        value = inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = commonSpecialArgs // {host = hostConfig;};
          modules = [../../home.nix];
        };
      })
      validHostNames # Use only valid hosts
    );
}
