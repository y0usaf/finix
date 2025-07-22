{
  lib,
  pkgs,
  hostsDir ? ../../hosts,
}: {
  mkNixosConfigurations = {
    inputs,
    system,
    commonSpecialArgs,
  }: let
    hostNames = ["y0usaf-desktop"];
    maidIntegration = import ./maid.nix {inherit hostsDir;};
  in
    builtins.listToAttrs (map
      (hostname: let
        hostConfig = import (hostsDir + "/${hostname}/default.nix") {
          inherit pkgs inputs;
        };
      in {
        name = hostname;
        value = inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs =
            commonSpecialArgs
            // {
              inherit hostname hostsDir;
              inherit (pkgs) lib;
              hostConfig = hostConfig;
              hostSystem = hostConfig.system;
            };
          modules = [
            ({config, ...}: {
              imports = hostConfig.system.imports;
              hostSystem = {
                username = hostConfig.system.username;
                hostname = hostConfig.system.hostname;
                homeDirectory = hostConfig.system.homeDirectory;
                stateVersion = hostConfig.system.stateVersion;
                timezone = hostConfig.system.timezone;
                profile = hostConfig.system.profile or "default";
                hardware = hostConfig.system.hardware or {};
                services = hostConfig.system.services or {};
              };
            })
            (maidIntegration.mkNixosModule {inherit inputs hostname;})
            ../../home
            inputs.chaotic.nixosModules.default
          ];
        };
      })
      hostNames);
}
