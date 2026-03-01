{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.dev.android-tools = {
    enable = lib.mkEnableOption "android-tools (adb, fastboot)";
  };

  config = lib.mkIf config.user.dev.android-tools.enable {
    environment.systemPackages = [
      pkgs.android-tools
    ];
  };
}
