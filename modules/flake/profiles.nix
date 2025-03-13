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
            (profilesDir + "/${hostname}/configuration.nix")
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = commonSpecialArgs // {profile = profiles.${hostname};};
                users.${profiles.${hostname}.username} = {
                  imports = [../../home.nix];
                  home = {
                    stateVersion = profiles.${hostname}.stateVersion;
                    homeDirectory = inputs.nixpkgs.lib.mkForce profiles.${hostname}.homeDirectory;
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
  }:
    builtins.listToAttrs (
      map
      (hostname: let
        profileConfig = import (profilesDir + "/${hostname}/default.nix") {
          lib = pkgs.lib;
          inherit pkgs;
        };
      in {
        name = profileConfig.username;
        value = inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = commonSpecialArgs // {profile = profileConfig;};
          modules = [../../home.nix];
        };
      })
      profileNames
    );
}
