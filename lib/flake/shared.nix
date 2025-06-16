###############################################################################
# Shared Flake Utilities
# Common functionality for discovering and importing unified host configurations
###############################################################################
{
  lib,
  pkgs,
  helpers,
  hostsDir ? ../../hosts,
  inputs ? null,
}: let
  # Get all valid host names (excluding special directories and files)
  hostNames = builtins.filter (
    name:
      name
      != "README.md"
      && name != "default.nix"
      && builtins.pathExists (hostsDir + "/${name}/default.nix")
  ) (builtins.attrNames (builtins.readDir hostsDir));

  # Import unified configurations for each host
  unifiedConfigs = builtins.listToAttrs (
    map
    (name: {
      inherit name;
      value = import (hostsDir + "/${name}/default.nix") {inherit lib pkgs inputs;};
    })
    hostNames
  );

  # Extract system configurations from unified configs
  systemConfigs = builtins.listToAttrs (
    map
    (name: {
      inherit name;
      value = {
        # Hardware configuration from system
        inherit (unifiedConfigs.${name}.system) hardware;
        system = {
          # Move imports into system scope to avoid HM exposure
          imports = unifiedConfigs.${name}.system.imports or [];
        };
        users = unifiedConfigs.${name}.users or {};
      };
    })
    hostNames
  );

  # Extract home configurations from unified configs (disabled for migration)
  homeConfigs = builtins.listToAttrs (
    map
    (name: {
      inherit name;
      value = unifiedConfigs.${name}.home or {};
    })
    hostNames
  );

  # Get valid host names with proper config structure
  validHostNames =
    builtins.filter (
      hostname:
        builtins.hasAttr hostname unifiedConfigs
        && builtins.hasAttr "shared" unifiedConfigs.${hostname}
        && builtins.hasAttr "username" unifiedConfigs.${hostname}.shared
    )
    hostNames;

  # Common specialArgs builder
  mkSpecialArgs = commonSpecialArgs: hostname:
    commonSpecialArgs
    // {
      hostSystem = systemConfigs.${hostname};
      hostHome = homeConfigs.${hostname};

      inherit helpers hostname;
    };

  # Generic listToAttrs + map helper
  mapToAttrs = f: list: builtins.listToAttrs (map f list);
  # Universal shared module function
  mkSharedModule = {
    hostname,
    hostsDir ? hostsDir,
  }: {
    lib,
    config,
    pkgs,
    ...
  }: let
    # Read the host configuration directly
    hostConfig =
      if hostname != null
      then
        import (hostsDir + "/${hostname}/default.nix") {
          inherit pkgs;
          inputs = null;
        }
      else throw "hostname must be provided to shared core module";

    # Extract shared configuration from host config
    sharedConfig = hostConfig.shared;
  in {
    options.shared = {
      username = lib.mkOption {
        type = lib.types.str;
        description = "System username for the primary user account";
        example = "alice";
      };

      hostname = lib.mkOption {
        type = lib.types.str;
        description = "System hostname";
        example = "alice-laptop";
      };

      homeDirectory = lib.mkOption {
        type = lib.types.path;
        description = "Path to the user's home directory";
        example = "/home/alice";
      };

      stateVersion = lib.mkOption {
        type = lib.types.str;
        description = "NixOS state version for compatibility";
        example = "24.11";
      };

      timezone = lib.mkOption {
        type = lib.types.str;
        description = "System timezone";
        example = "America/New_York";
      };

      config = lib.mkOption {
        type = lib.types.str;
        description = "Configuration profile identifier";
        default = "default";
        example = "desktop";
      };

      tokenDir = lib.mkOption {
        type = lib.types.str;
        description = "Directory containing token files to be loaded as environment variables";
        example = "/home/alice/Tokens";
      };

      zsh = lib.mkOption {
        type = lib.types.submodule {
          options = {
            cat-fetch = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Print colorful cats on shell startup";
            };
            history-memory = lib.mkOption {
              type = lib.types.int;
              default = 1000;
              description = "Number of history entries to keep in memory";
            };
            history-storage = lib.mkOption {
              type = lib.types.int;
              default = 1000;
              description = "Number of history entries to save to disk";
            };
            enableFancyPrompt = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable the custom PS1 prompt";
            };
            zellij = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  enable = lib.mkOption {
                    type = lib.types.bool;
                    default = false;
                    description = "Enable zellij terminal multiplexer";
                  };
                };
              };
              default = {};
              description = "Zellij terminal multiplexer configuration";
            };
          };
        };
        default = {};
        description = "Zsh shell configuration options";
      };
    };

    # Automatically set the shared configuration from host config
    config = {
      shared = sharedConfig;

      # Add any shared assertions, warnings, or common config here
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
  inherit hostNames unifiedConfigs systemConfigs homeConfigs validHostNames mkSpecialArgs mapToAttrs mkSharedModule;
}