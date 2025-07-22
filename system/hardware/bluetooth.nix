{
  config,
  lib,
  pkgs,
  hostSystem,
  ...
}: let
  hardwareCfg = hostSystem.hardware;
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
    environment.systemPackages = with pkgs;
      lib.optionals (hardwareCfg.bluetooth.enable or false) [
        bluez
        bluez-tools
      ];
    users.users.${config.hostSystem.username}.extraGroups =
      lib.optionals (hardwareCfg.bluetooth.enable or false) ["dialout" "bluetooth" "lp"];
  };
}
