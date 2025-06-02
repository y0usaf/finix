#═══════════════════════════ 🔧 SYSTEM CONFIGURATION MODULE 🔧 ═══════════════════════════#
{
  config,
  lib,

  ...
}: {
  # No need for module-defs import - using lib directly
  options.cfg.system = {
    username = lib.mkOption {
      type = lib.types.str;
      default = config.cfg.shared.username;
      description = "The username for the system.";
    };
    hostname = lib.mkOption {
      type = lib.types.str;
      default = config.cfg.shared.hostname;
      description = "The system hostname.";
    };
    homeDirectory = lib.mkOption {
      type = lib.types.str;
      default = config.cfg.shared.homeDirectory;
      description = "The path to the user's home directory.";
    };
    stateVersion = lib.mkOption {
      type = lib.types.str;
      default = config.cfg.shared.stateVersion;
      description = "The system state version.";
    };
    timezone = lib.mkOption {
      type = lib.types.str;
      default = config.cfg.shared.timezone;
      description = "The system timezone.";
    };
    config = lib.mkOption {
      type = lib.types.str;
      default = config.cfg.shared.config;
      description = "The system configuration type.";
    };
  };

  # Core GPU modules
  options.cfg.core = {
    nvidia = {
      enable = lib.mkEnableOption "NVIDIA GPU support";
    };
    amdgpu = {
      enable = lib.mkEnableOption "AMD GPU support";
    };
  };

  config.home = {
    inherit (config.cfg.system) username homeDirectory stateVersion;
    enableNixpkgsReleaseCheck = false;
  };
}
