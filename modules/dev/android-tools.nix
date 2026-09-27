{
  config,
  pkgs,
  ...
}: {
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
}
