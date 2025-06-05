###############################################################################
# Web Applications Module
# Provides Chromium browser for web applications with desktop entries
# - Keyboard testing utility (Keybard)
# - Google Meet video conferencing
###############################################################################
{
  config,
  lib,
  pkgs,
  xdg,
  ...
}: let
  cfg = config.cfg.hjome.programs.webapps;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.hjome.programs.webapps = {
    enable = lib.mkEnableOption "web applications via Chromium";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    packages = [pkgs.chromium];

    ###########################################################################
    # Desktop Entries
    ###########################################################################
    files = {
      ${xdg.dataFile "applications/keybard.desktop"}.text = ''
        [Desktop Entry]
        Name=Keybard
        Exec=${lib.getExe pkgs.chromium} --app=https://captdeaf.github.io/keybard %U
        Terminal=false
        Type=Application
        Categories=Utility;System;
        Comment=Keyboard testing utility
      '';

      ${xdg.dataFile "applications/google-meet.desktop"}.text = ''
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
}
