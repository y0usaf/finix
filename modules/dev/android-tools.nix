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
    finix.persistence.allowlist.users.${config.user.name} = {
      directories = [
        ".local/share/android"
        ".local/share/android/.android"
      ];
      files = [
        ".local/share/android/adbkey"
        ".local/share/android/adbkey.pub"
      ];
    };
    environment.systemPackages = [
      pkgs.android-tools
    ];
  };
}
