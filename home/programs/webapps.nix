###############################################################################
# Web Applications Module (Maid)
# Provides Chromium browser for web applications with desktop entries
# - Keyboard testing utility (Keybard)
# - Google Meet video conferencing
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.programs.webapps;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.home.programs.webapps = {
    enable = lib.mkEnableOption "web applications via Chromium";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Maid Configuration
    ###########################################################################
    users.users.y0usaf.maid = {
      packages = [pkgs.chromium];

      file = {
        home.".local/share/applications/keybard.desktop".text = ''
          [Desktop Entry]
          Name=Keybard
          Exec=${lib.getExe pkgs.chromium} --app=https://captdeaf.github.io/keybard %U
          Terminal=false
          Type=Application
          Categories=Utility;System;
          Comment=Keyboard testing utility
        '';

        home.".local/share/applications/google-meet.desktop".text = ''
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
}
