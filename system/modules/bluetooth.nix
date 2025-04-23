###############################################################################
# Bluetooth Configuration Module (Comprehensive System Level)
# Controls all system-level Bluetooth functionality
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
  # Module Options (simplified approach)
  ###########################################################################
  options.cfg.hardware.bluetooth = {
    # Single option to control Bluetooth functionality
    enable = lib.mkEnableOption "Complete Bluetooth stack (hardware, services, and tools)";
    
    # Advanced settings (optional)
    settings = lib.mkOption {
      type = lib.types.attrs;
      default = {
        General = {
          ControllerMode = "dual";
          FastConnectable = true;
        };
      };
      description = "Settings for the Bluetooth configuration";
    };
  };

  ###########################################################################
  # Module Configuration (comprehensive system level)
  ###########################################################################
  config = lib.mkIf cfg.enable {
    # 1. Enable hardware Bluetooth support
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true; # Always power on if Bluetooth is enabled
      settings = cfg.settings;
      package = pkgs.bluez;
    };
    
    # 2. Enable Blueman service at system level
    services.blueman.enable = true;
    
    # 3. Install required system packages
    environment.systemPackages = with pkgs; [
      bluez
      bluez-tools
      blueman
    ];
    
    # 4. Add user to necessary groups
    users.users.y0usaf.extraGroups = ["dialout" "bluetooth"];
  };
}
