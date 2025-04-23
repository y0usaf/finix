###############################################################################
# Bluetooth Configuration Module
# Configures Bluetooth hardware and management utilities
# - Bluetooth hardware support
# - Blueman graphical manager
# - Power-on behavior
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
  # Module Options
  ###########################################################################
  options.cfg.hardware.bluetooth = {
    enable = lib.mkEnableOption "Bluetooth support";
    
    powerOnBoot = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to power up the default Bluetooth controller on boot";
    };
    
    # Blueman is now handled at the home level
    
    settings = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Settings for the main Bluetooth configuration";
      example = lib.literalExpression ''
        {
          General = {
            ControllerMode = "bredr";
            FastConnectable = true;
            JustWorksRepairing = "always";
          };
        }
      '';
    };
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    # Enable Bluetooth hardware support
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = cfg.powerOnBoot;
      settings = cfg.settings;
    };
    
    # Blueman service is now controlled at the home level
    
    # Install additional Bluetooth utilities
    environment.systemPackages = with pkgs; [
      bluez
      bluez-tools
    ];
  };
}