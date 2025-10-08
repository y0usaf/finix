{
  lib,
  pkgs,
  hostConfig,
  ...
}: let
  bluetoothCfg = lib.attrByPath ["hardware" "bluetooth"] {} hostConfig;
  bluetoothEnabled = bluetoothCfg.enable or false;
in {
  config = {
    hardware.bluetooth = lib.mkIf bluetoothEnabled {
      enable = true;
      powerOnBoot = true;
      settings =
        bluetoothCfg.settings or {
          General = {
            ControllerMode = "dual";
            FastConnectable = true;
          };
        };
      package = pkgs.bluez;
    };
    services.dbus.packages = lib.mkIf bluetoothEnabled [pkgs.bluez];
    environment.systemPackages = lib.optionals bluetoothEnabled [
      pkgs.bluez
      pkgs.bluez-tools
    ];
  };
}
