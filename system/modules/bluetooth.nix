###############################################################################
# Bluetooth Configuration Module (Minimal System Level)
# Provides only the essential system-level Bluetooth support
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.cfg.hardware.bluetooth;
in {
  ###########################################################################
  # Module Options (minimal system configuration)
  ###########################################################################
  options.cfg.hardware.bluetooth = {
    enable = lib.mkEnableOption "Bluetooth support";
    
    powerOnBoot = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to power up the default Bluetooth controller on boot";
    };
    
    settings = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Settings for the Bluetooth configuration";
    };
  };

  ###########################################################################
  # Module Configuration (minimal system level)
  ###########################################################################
  config = lib.mkIf cfg.enable {
    # Enable core Bluetooth support at system level
    # This is the minimal required configuration
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = cfg.powerOnBoot;
      settings = cfg.settings;
      # Use standard bluez package for better compatibility
      package = pkgs.bluez;
    };
    
    # Don't enable blueman at system level - will be handled in home config
    # services.blueman.enable = false;
    
    # Only install the core Bluetooth packages at system level
    environment.systemPackages = with pkgs; [
      bluez
      bluez-tools
    ];
  };
}
