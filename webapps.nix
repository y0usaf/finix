{
  config,
  lib,
  pkgs,
  profile,
  ...
}: {
  config = lib.mkIf profile.enableWebapps {
    # Add chromium package
    home.packages = [pkgs.chromium];

    xdg.desktopEntries = {
      "keybard" = {
        name = "Keybard";
        exec = "${lib.getExe pkgs.chromium} --app=https://captdeaf.github.io/keybard %U";
        terminal = false;
        categories = ["Utility" "System"];
        comment = "Keyboard testing utility";
      };

      "google-meet" = {
        name = "Google Meet";
        exec = "${lib.getExe pkgs.chromium} --app=https://meet.google.com %U";
        terminal = false;
        categories = ["Network" "VideoConference" "Chat"];
        comment = "Video conferencing by Google";
      };
    };
  };
}
