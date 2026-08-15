{
  config,
  lib,
  pkgs,
  ...
}: {
  # Only the package list survives the compat shim (environment.*); the
  # hardware.bluetooth / services.dbus config was NixOS-only and dropped.
  # hardware.bluetooth.enable is a finix-native stub option (default true).
  config = lib.mkIf config.hardware.bluetooth.enable {
    environment.systemPackages = [
      pkgs.bluez
      pkgs.bluez-tools
    ];
  };
}