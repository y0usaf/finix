###############################################################################
# Hardware Configuration Module
# Hardware-specific settings excluding NVIDIA (which has its own module):
# - Graphics configuration
# - I2C bus for hardware monitoring
# - AMD GPU configuration
# - Bluetooth stack configuration
###############################################################################
{
  config,
  lib,
  pkgs,
  hostSystem,
  hostHome,
  ...
}: let
  cfg = hostSystem.cfg.hardware;
  coreCfg = hostSystem.cfg.core;
in {
  config = {
    ###########################################################################
    # Hardware-Specific Settings
    # Configuration for specific hardware drivers and graphics
    ###########################################################################
    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          vaapiVdpau
          libvdpau-va-gl
        ];
      };

      i2c.enable = true;
    };

    ###########################################################################
    # AMD GPU X Server Configuration (conditional)
    # X server driver settings for AMD GPU
    ###########################################################################
    services.xserver.videoDrivers = lib.mkIf hostSystem.cfg.core.amdgpu.enable ["amdgpu"];

    ###########################################################################
    # Bluetooth Configuration (conditional)
    # Complete Bluetooth stack when enabled in host config
    ###########################################################################
    hardware.bluetooth = lib.mkIf (coreCfg.bluetooth.enable or false) {
      enable = true;
      powerOnBoot = true;
      settings =
        coreCfg.bluetooth.settings or {
          General = {
            ControllerMode = "dual";
            FastConnectable = true;
          };
        };
      # Use bluez for maximum compatibility with all BT protocols
      package = pkgs.bluez;
    };

    # Bluetooth-related services and packages (conditional)
    services.dbus.packages = lib.mkIf (coreCfg.bluetooth.enable or false) [pkgs.bluez];

    # Add required system packages for Bluetooth
    environment.systemPackages = with pkgs;
      lib.optionals (coreCfg.bluetooth.enable or false) [
        bluez
        bluez-tools
      ];

    # Add user to necessary groups for Bluetooth
    users.users.${hostSystem.cfg.system.username}.extraGroups =
      lib.optionals (coreCfg.bluetooth.enable or false) ["dialout" "bluetooth" "lp"];
  };
}
