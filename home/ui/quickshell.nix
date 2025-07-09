###############################################################################
# Quickshell Module
# Qt-based desktop shell
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.ui.quickshell;
  inherit (config.shared) username;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.home.ui.quickshell = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Quickshell desktop shell";
    };

    widgets = {
      statusBar = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable status bar";
        };
        
        position = lib.mkOption {
          type = lib.types.enum ["top" "bottom"];
          default = "top";
          description = "Status bar position";
        };
        
        height = lib.mkOption {
          type = lib.types.int;
          default = 30;
          description = "Status bar height in pixels";
        };
      };

      workspaceOverview = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable workspace overview";
        };
      };

      systemTray = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable system tray";
        };
      };

      notifications = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable notifications";
        };
      };

      clock = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable clock widget";
        };
        
        format = lib.mkOption {
          type = lib.types.str;
          default = "hh:mm";
          description = "Clock time format";
        };
      };

      battery = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable battery widget";
        };
      };

      audio = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable audio widget";
        };
      };

      bluetooth = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable bluetooth widget";
        };
      };

      media = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable media player widget";
        };
      };
    };
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Maid Configuration
    ###########################################################################
    users.users.${username}.maid = {
      packages = with pkgs; [
        quickshell
        cava
      ];
    };
  };
}
