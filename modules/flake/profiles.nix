{
  lib,
  pkgs,
  profilesDir ? ../../profiles,
}: let
  # Get all valid profile names
  profileNames = builtins.filter (
    name:
      name
      != "README.md"
      && name != "configurations"
      && name != "options.nix"
      && builtins.pathExists (profilesDir + "/${name}/default.nix")
  ) (builtins.attrNames (builtins.readDir profilesDir));

  # Import all available profiles dynamically
  profiles = builtins.listToAttrs (
    map
    (name: {
      inherit name;
      value = import (profilesDir + "/${name}") {
        inherit lib pkgs;
      };
    })
    profileNames
  );
in {
  inherit profileNames profiles;

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
          specialArgs = commonSpecialArgs // {profile = profiles.${hostname};};
          modules = [
            # Import hardware configuration directly
            (profilesDir + "/${hostname}/hardware-configuration.nix")
            # Import the shared configurations
            (profilesDir + "/configurations/default.nix")
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = commonSpecialArgs // {profile = profiles.${hostname};};
                users.${profiles.${hostname}.cfg.system.username} = {
                  imports = [../../home.nix];
                  home = {
                    stateVersion = profiles.${hostname}.cfg.system.stateVersion;
                    homeDirectory = inputs.nixpkgs.lib.mkForce profiles.${hostname}.cfg.system.homeDirectory;
                  };
                };
              };
            }
            inputs.chaotic.nixosModules.default
          ];
        };
      })
      profileNames
    );

  # Helper function to generate homeConfigurations
  mkHomeConfigurations = {
    inputs,
    pkgs,
    commonSpecialArgs,
  }: let
    # Debug: Check if profiles have the expected structure
    validProfileNames =
      builtins.filter (
        hostname:
          builtins.hasAttr hostname profiles
          && builtins.hasAttr "modules" profiles.${hostname}
          && builtins.hasAttr "system" profiles.${hostname}.modules
          && builtins.hasAttr "username" profiles.${hostname}.cfg.system
      )
      profileNames;
  in
    builtins.listToAttrs (
      map
      (hostname: let
        profileConfig = profiles.${hostname};
      in {
        name = profileConfig.cfg.system.username;
        value = inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = commonSpecialArgs // {profile = profileConfig;};
          modules = [../../home.nix];
        };
      })
      validProfileNames # Use only valid profiles
    );
}
