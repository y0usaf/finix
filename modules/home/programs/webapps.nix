{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.programs.webapps;
in {
  options.home.programs.webapps = {
    enable = lib.mkEnableOption "web applications via Chromium";
  };
  config = lib.mkIf cfg.enable {
    hjem.users.${config.user.name} = {
      packages = [pkgs.ungoogled-chromium];
      files = {
        ".local/share/applications/keybard.desktop" = {
          clobber = true;
          text = ''
            [Desktop Entry]
            Name=Keybard
            Exec=${lib.getExe pkgs.chromium} --app=https://captdeaf.github.io/keybard %U
            Terminal=false
            Type=Application
            Categories=Utility;System;
            Comment=Keyboard testing utility
          '';
        };
        ".local/share/applications/google-meet.desktop" = {
          clobber = true;
          text = ''
            [Desktop Entry]
            Name=Google Meet
            Exec=${lib.getExe pkgs.chromium} --app=https://meet.google.com %U
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
