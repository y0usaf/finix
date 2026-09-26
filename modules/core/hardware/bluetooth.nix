{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.hardware.bluetooth.enable {
    environment.systemPackages = [
      pkgs.bluez
      pkgs.bluez-tools
    ];
  };
}
