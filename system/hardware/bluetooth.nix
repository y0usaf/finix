###############################################################################
# Bluetooth Configuration Module
# - Bluetooth stack settings
# - Bluetooth services and packages
###############################################################################
{
  config,
  lib,
  pkgs,

  hostSystem,
  ...
}: let
  hardwareCfg = hostSystem.cfg.hardware;
in {
  config = {
    ###########################################################################
    # Bluetooth Configuration (conditional)
    # Complete Bluetooth stack when enabled in host config
    ###########################################################################
    hardware.bluetooth = lib.mkIf (hardwareCfg.bluetooth.enable or false) {
      enable = true;
      powerOnBoot = true;
      settings =
        hardwareCfg.bluetooth.settings
        or {
          General = {
            ControllerMode = "dual";
            FastConnectable = true;
          };
        };
      # Use bluez for maximum compatibility with all BT protocols
      package = pkgs.bluez;
    };

    # Bluetooth-related services and packages (conditional)
    services.dbus.packages = lib.mkIf (hardwareCfg.bluetooth.enable or false) [pkgs.bluez];

    # Add required system packages for Bluetooth
    environment.systemPackages = with pkgs;
      lib.optionals (hardwareCfg.bluetooth.enable or false) [
        bluez
        bluez-tools
      ];

    # Add user to necessary groups for Bluetooth
    users.users.${config.cfg.shared.username}.extraGroups =
      lib.optionals (hardwareCfg.bluetooth.enable or false) ["dialout" "bluetooth" "lp"];
  };
}
