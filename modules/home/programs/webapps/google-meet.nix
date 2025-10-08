{
  config,
  lib,
  pkgs,
  ...
}: {
  options.home.programs.google-meet = {
    enable = lib.mkEnableOption "Google Meet webapp";
  };
  config = lib.mkIf config.home.programs.google-meet.enable {
    usr = {
      files = {
        ".local/share/applications/google-meet.desktop" = {
          clobber = true;
          text = ''
            [Desktop Entry]
            Name=Google Meet
            Exec=${lib.getExe pkgs.chromium} --app=https://meet.google.com --force-dark-mode %U
            Terminal=false
            Type=Application
            Categories=Network;VideoConference;Chat;
            Comment=Video conferencing by Google
          '';
        };
      };
    };
  };
}
