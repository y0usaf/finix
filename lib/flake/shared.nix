###############################################################################
# Shared Flake Utilities
# Common functionality for discovering and importing unified host configurations
###############################################################################
{
  lib,
  pkgs,
  helpers,
  hostsDir ? ../../hosts,
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
      value = import (hostsDir + "/${name}/default.nix") {inherit lib pkgs;};
    })
    hostNames
  );

  # Extract system configurations from unified configs
  systemConfigs = builtins.listToAttrs (
    map
    (name: {
      inherit name;
      value = {
        cfg = {
          # Move hardware to top level for system modules
          inherit (unifiedConfigs.${name}.cfg.system) hardware;
          system = {
            # Move imports into system scope to avoid HM exposure
            imports = unifiedConfigs.${name}.imports or [];
            inherit (unifiedConfigs.${name}.cfg.system) hardware;
          };
        };
        users = unifiedConfigs.${name}.users or {};
      };
    })
    hostNames
  );

  # Extract home configurations from unified configs (disabled for Hjem migration)
  homeConfigs = builtins.listToAttrs (
    map
    (name: {
      inherit name;
      value = {
        cfg = unifiedConfigs.${name}.cfg.home or {};
      };
    })
    hostNames
  );

  # Extract hjem configurations from unified configs
  hjemConfigs = builtins.listToAttrs (
    map
    (name: {
      inherit name;
      value = {
        cfg = {
          hjome = unifiedConfigs.${name}.cfg.hjome or {};
        };
      };
    })
    hostNames
  );

  # Get valid host names with proper config structure
  validHostNames =
    builtins.filter (
      hostname:
        builtins.hasAttr hostname unifiedConfigs
        && builtins.hasAttr "cfg" unifiedConfigs.${hostname}
        && builtins.hasAttr "shared" unifiedConfigs.${hostname}.cfg
        && builtins.hasAttr "username" unifiedConfigs.${hostname}.cfg.shared
    )
    hostNames;

  # Common specialArgs builder
  mkSpecialArgs = commonSpecialArgs: hostname:
    commonSpecialArgs
    // {
      hostSystem = systemConfigs.${hostname};
      hostHome = homeConfigs.${hostname};
      hostHjem = hjemConfigs.${hostname};
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
      then import (hostsDir + "/${hostname}/default.nix") {inherit pkgs;}
      else throw "hostname must be provided to shared core module";

    # Extract shared configuration from host config
    sharedConfig = hostConfig.cfg.shared;
  in {
    options.cfg.shared = {
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
      cfg.shared = sharedConfig;

      # Add any shared assertions, warnings, or common config here
      assertions = [
        {
          assertion = config.cfg.shared.username != "";
          message = "Username cannot be empty";
        }
        {
          assertion = config.cfg.shared.hostname != "";
          message = "Hostname cannot be empty";
        }
      ];
    };
  };
in {
  inherit hostNames unifiedConfigs systemConfigs homeConfigs hjemConfigs validHostNames mkSpecialArgs mapToAttrs mkSharedModule;
}
