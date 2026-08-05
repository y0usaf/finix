{
  config,
  lib,
  pkgs,
  ...
}: let
  adbWirelessQrPython = pkgs.python3.withPackages (ps: [
    ps.qrcode
    ps.zeroconf
  ]);
in {
  options.user.dev.android-tools = {
    enable = lib.mkEnableOption "android-tools (adb, fastboot)";
  };

  config = lib.mkIf config.user.dev.android-tools.enable {
    environment.systemPackages = [
      pkgs.android-tools
      (pkgs.writeShellScriptBin "adb-wireless-qr" ''
        exec ${adbWirelessQrPython}/bin/python3 ${./adb-wireless-qr.py} "$@"
      '')
    ];
  };
}