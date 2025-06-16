###############################################################################
# System Configuration Options
# Defines system-level configuration options used by system modules and host configs
###############################################################################
{
  config,
  lib,
  ...
}: {
  # System-level configuration options
  options.system = {
    username = lib.mkOption {
      type = lib.types.str;
      default = config.shared.username;
      description = "The username for the system.";
    };
    hostname = lib.mkOption {
      type = lib.types.str;
      default = config.shared.hostname;
      description = "The system hostname.";
    };
    homeDirectory = lib.mkOption {
      type = lib.types.str;
      default = config.shared.homeDirectory;
      description = "The path to the user's home directory.";
    };
    timezone = lib.mkOption {
      type = lib.types.str;
      default = config.shared.timezone;
      description = "The system timezone.";
    };
    config = lib.mkOption {
      type = lib.types.str;
      default = config.shared.config;
      description = "The system configuration type.";
    };
  };

  # Configuration
  config = {
    system.stateVersion = config.shared.stateVersion;
    time.timeZone = config.shared.timezone;
    networking.hostName = config.shared.hostname;
    nixpkgs.config.allowUnfree = true;
  };
}