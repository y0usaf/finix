{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.hardware.bluetooth.enable {
    hardware.bluetooth = {
      powerOnBoot = lib.mkDefault true;
      settings = lib.mkDefault {
        General = {
          ControllerMode = "dual";
          FastConnectable = true;
        };
      };
      package = lib.mkDefault pkgs.bluez;
    };
    services.dbus.packages = [pkgs.bluez];
    environment.systemPackages = [
      pkgs.bluez
      pkgs.bluez-tools
    ];
  };
}
