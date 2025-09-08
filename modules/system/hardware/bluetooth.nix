{
  lib,
  pkgs,
  hostConfig,
  ...
}: let
  hardwareCfg = hostConfig.hardware;
in {
  config = {
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
      package = pkgs.bluez;
    };
    services.dbus.packages = lib.mkIf (hardwareCfg.bluetooth.enable or false) [pkgs.bluez];
    environment.systemPackages = lib.optionals (hardwareCfg.bluetooth.enable or false) [
      pkgs.bluez
      pkgs.bluez-tools
    ];
  };
}
