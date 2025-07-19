###############################################################################
# System Configuration
# Core system settings and options - no external dependencies
###############################################################################
{
  config,
  lib,
  ...
}: {
  # Define system-specific configuration options
  options.hostSystem = {
    # Core system identity
    username = lib.mkOption {
      type = lib.types.str;
      description = "Primary system username";
    };
    
    hostname = lib.mkOption {
      type = lib.types.str;
      description = "System hostname";
    };
    
    homeDirectory = lib.mkOption {
      type = lib.types.path;
      description = "Primary user home directory path";
    };
    
    # System settings
    stateVersion = lib.mkOption {
      type = lib.types.str;
      description = "NixOS state version for compatibility";
    };
    
    timezone = lib.mkOption {
      type = lib.types.str;
      description = "System timezone";
    };
    
    # Configuration metadata
    profile = lib.mkOption {
      type = lib.types.str;
      description = "Configuration profile identifier";
      default = "default";
    };

    # Hardware configuration options
    hardware = lib.mkOption {
      type = lib.types.attrs;
      description = "Hardware configuration options";
      default = {};
    };

    # Services configuration options
    services = lib.mkOption {
      type = lib.types.attrs;
      description = "System services configuration";
      default = {};
    };
  };

  config = {
    # Set core NixOS configuration based on system options
    system.stateVersion = config.hostSystem.stateVersion;
    time.timeZone = config.hostSystem.timezone;
    networking.hostName = config.hostSystem.hostname;
    
    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;
    
    # Validation
    assertions = [
      {
        assertion = config.hostSystem.username != "";
        message = "System username cannot be empty";
      }
      {
        assertion = config.hostSystem.hostname != "";
        message = "System hostname cannot be empty";
      }
      {
        assertion = lib.hasPrefix "/" (toString config.hostSystem.homeDirectory);
        message = "Home directory must be an absolute path";
      }
    ];
  };
}