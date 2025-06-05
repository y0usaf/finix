###############################################################################
# Web Applications Module
# Provides web applications as desktop entries using Chromium
# - Keyboard testing utility (Keybard)
# - Google Meet video conferencing
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.cfg.programs.webapps;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.programs.webapps = {
    enable = lib.mkEnableOption "web applications";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    home.packages = [pkgs.chromium];

    ###########################################################################
    # Desktop Entries
    ###########################################################################
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
