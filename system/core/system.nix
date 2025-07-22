{
  config,
  lib,
  ...
}: {
  options.hostSystem = {
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
    stateVersion = lib.mkOption {
      type = lib.types.str;
      description = "NixOS state version for compatibility";
    };
    timezone = lib.mkOption {
      type = lib.types.str;
      description = "System timezone";
    };
    profile = lib.mkOption {
      type = lib.types.str;
      description = "Configuration profile identifier";
      default = "default";
    };
    hardware = lib.mkOption {
      type = lib.types.attrs;
      description = "Hardware configuration options";
      default = {};
    };
    services = lib.mkOption {
      type = lib.types.attrs;
      description = "System services configuration";
      default = {};
    };
  };
  config = {
    system.stateVersion = config.hostSystem.stateVersion;
    time.timeZone = config.hostSystem.timezone;
    networking.hostName = config.hostSystem.hostname;
    nixpkgs.config.allowUnfree = true;
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
