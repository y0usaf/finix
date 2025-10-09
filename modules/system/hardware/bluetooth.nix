{
  config,
  lib,
  pkgs,
  ...
}: {
  config = {
    hardware.bluetooth = lib.mkIf config.hardware.bluetooth.enable {
      powerOnBoot = lib.mkDefault true;
      settings = lib.mkDefault {
        General = {
          ControllerMode = "dual";
          FastConnectable = true;
        };
      };
      package = lib.mkDefault pkgs.bluez;
    };
    services.dbus.packages = lib.mkIf config.hardware.bluetooth.enable [pkgs.bluez];
    environment.systemPackages = lib.optionals config.hardware.bluetooth.enable [
      pkgs.bluez
      pkgs.bluez-tools
    ];
  };
}
