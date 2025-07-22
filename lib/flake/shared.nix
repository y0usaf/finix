{
  lib,
  pkgs,
  hostsDir ? ../../hosts,
  inputs ? null,
}: let
  hostNames = ["y0usaf-desktop"];
  unifiedConfigs = builtins.listToAttrs (
    map
    (name: {
      inherit name;
      value = import (hostsDir + "/${name}/default.nix") {inherit lib pkgs inputs;};
    })
    hostNames
  );
  systemConfigs = builtins.listToAttrs (
    map
    (name: {
      inherit name;
      value = {
        inherit (unifiedConfigs.${name}.system) hardware;
        inherit (unifiedConfigs.${name}.system) services;
        system = {
          imports = unifiedConfigs.${name}.system.imports or [];
        };
        users = unifiedConfigs.${name}.users or {};
      };
    })
    hostNames
  );
  homeConfigs = builtins.listToAttrs (
    map
    (name: {
      inherit name;
      value = unifiedConfigs.${name}.home or {};
    })
    hostNames
  );
  mkSpecialArgs = commonSpecialArgs: hostname:
    commonSpecialArgs
    // {
      hostSystem = systemConfigs.${hostname};
      hostHome = homeConfigs.${hostname};
      inherit hostname;
    };
  mkSharedModule = {
    hostname,
    hostsDir ? hostsDir,
  }: {
    lib,
    config,
    pkgs,
    ...
  }: let
    hostConfig =
      if hostname != null
      then
        import (hostsDir + "/${hostname}/default.nix") {
          inherit pkgs;
          inputs = null;
        }
      else throw "hostname must be provided to shared core module";
    sharedConfig = hostConfig.shared;
  in {
    options.shared = {
      username = lib.mkOption {
        type = lib.types.str;
        description = "System username for the primary user account";
      };
      hostname = lib.mkOption {
        type = lib.types.str;
        description = "System hostname";
      };
      homeDirectory = lib.mkOption {
        type = lib.types.path;
        description = "Path to the user's home directory";
      };
      stateVersion = lib.mkOption {
        type = lib.types.str;
        description = "NixOS state version for compatibility";
      };
      timezone = lib.mkOption {
        type = lib.types.str;
        description = "System timezone";
      };
      config = lib.mkOption {
        type = lib.types.str;
        description = "Configuration profile identifier";
        default = "default";
      };
      tokenDir = lib.mkOption {
        type = lib.types.str;
        description = "Directory containing token files";
      };
      zsh = lib.mkOption {
        type = lib.types.submodule {
          options = {
            cat-fetch = lib.mkOption {
              type = lib.types.bool;
              default = true;
            };
            history-memory = lib.mkOption {
              type = lib.types.int;
              default = 1000;
            };
            history-storage = lib.mkOption {
              type = lib.types.int;
              default = 1000;
            };
            enableFancyPrompt = lib.mkOption {
              type = lib.types.bool;
              default = true;
            };
            zellij = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  enable = lib.mkOption {
                    type = lib.types.bool;
                    default = false;
                  };
                };
              };
              default = {};
            };
          };
        };
        default = {};
      };
    };
    config = {
      shared = sharedConfig;
      assertions = [
        {
          assertion = config.shared.username != "";
          message = "Username cannot be empty";
        }
        {
          assertion = config.shared.hostname != "";
          message = "Hostname cannot be empty";
        }
      ];
    };
  };
in {
  inherit hostNames unifiedConfigs systemConfigs homeConfigs mkSpecialArgs mkSharedModule;
}
