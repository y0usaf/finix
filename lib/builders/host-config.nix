{
  lib,
  sources,
  overlays,
  hostsDir,
  userConfigs,
}: {
  # Helper to build a single host configuration
  mkHostConfig = hostname: {
    inputs,
    system,
    commonSpecialArgs,
    pkgs,
  }: let
    hostConfig = import (hostsDir + "/${hostname}/default.nix") {
      inherit pkgs inputs;
    };

    users = hostConfig.users;
    hostUserConfigs = lib.genAttrs users (username: userConfigs.${username});

    maidIntegration = import ../core/maid.nix {inherit hostsDir;};
  in {
    name = hostname;
    value = import (sources.nixpkgs + "/nixos") {
      inherit system;
      configuration = {
        imports = [
          # Host system configuration
          ({config, ...}: {
            imports = hostConfig.imports;
            hostSystem = {
              users = hostConfig.users;
              hostname = hostConfig.hostname;
              homeDirectory = hostConfig.homeDirectory;
              stateVersion = hostConfig.stateVersion;
              timezone = hostConfig.timezone;
              profile = hostConfig.profile or "default";
              hardware = hostConfig.hardware or {};
              services = hostConfig.services or {};
            };

            # Configure nixpkgs with overlays
            nixpkgs.overlays = overlays;
            nixpkgs.config.allowUnfree = true;
            nixpkgs.config.cudaSupport = true;
          })

          # User home configurations via maid
          (maidIntegration.mkNixosModule {
            inherit inputs hostname users;
            userConfigs = hostUserConfigs;
          })

          # Import home manager
          ../../home

          # TODO: Fix chaotic integration
          # (inputs.chaotic.outPath + "/modules/nixos/default.nix")
        ];

        _module.args =
          commonSpecialArgs
          // {
            inherit hostname hostsDir users;
            lib = lib; # Use the extended lib
            hostConfig = hostConfig;
            userConfigs = hostUserConfigs;
            hostSystem = hostConfig;
          };
      };
    };
  };
}
