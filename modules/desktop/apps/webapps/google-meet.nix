{
  config,
  lib,
  pkgs,
  ...
}: {
  manzil.users."${config.user.name}" = {
    files = {
      ".local/share/applications/google-meet.desktop" = {
        generator = lib.generators.toINI {};
        value."Desktop Entry" = {
          Name = "Google Meet";
          Exec = "${lib.getExe pkgs.chromium} --app=https://meet.google.com --enable-features=WebContentsForceDark %U";
          Terminal = false;
          Type = "Application";
          Categories = "Network;VideoConference;Chat;";
          Comment = "Video conferencing by Google";
        };
      };
    };
  };
}
