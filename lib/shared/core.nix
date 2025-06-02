###############################################################################
# Shared Core Configuration Module
# Defines options and configuration shared across all module systems
# (NixOS system, Home Manager, and Hjem)
###############################################################################
{ lib, config, ... }: {
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
  };

  # Common configuration that applies to all module systems
  config = {
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
}