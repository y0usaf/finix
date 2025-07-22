{
  lib,
  pkgs,
  sources,
  hostsDir ? ../hosts,
}: {
  mkNixosConfigurations = {
    inputs,
    system,
    commonSpecialArgs,
  }: let
    hostNames = ["y0usaf-desktop"];
    maidIntegration = import ./flake/maid.nix {inherit hostsDir;};
  in
    builtins.listToAttrs (map
      (hostname: let
        hostConfig = import (hostsDir + "/${hostname}/default.nix") {
          inherit pkgs inputs;
        };
      in {
        name = hostname;
        value = import (sources.nixpkgs + "/nixos") {
          inherit system;
          configuration = {
            imports = [
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
              ../home
              # (inputs.chaotic.outPath + "/modules/nixos/default.nix") # TODO: Fix chaotic integration
            ];
            _module.args =
              commonSpecialArgs
              // {
                inherit hostname hostsDir;
                lib = lib; # Use the extended lib passed to npins-system.nix
                hostConfig = hostConfig;
                hostSystem = hostConfig.system;
              };
          };
        };
      })
      hostNames);
}
