#===============================================================================
#                      📊 Waybar Configuration 📊
#===============================================================================
# 🎨 Status bar style
# 📱 Module layout
# 🔧 System monitors
# 🖥️ Display config
#===============================================================================
{
  config,
  pkgs,
  lib,
  globals,
  ...
}: let
  mkModule = name: config: {${name} = config;};

  commonModules = {
    clock = {
      format = "{:%H:%M:%OS %d/%m }| ";
      interval = 1;
    };
    battery = {};
    tray = {};
    "hyprland/workspaces" = {};
  };

  desktopModules = lib.optionalAttrs (globals.hostname == "y0usaf-desktop") {
    "custom/ram" = {
      format = "RAM: {} MB | ";
      exec = "free -m | awk '/^Mem:/{print $3}'";
      interval = 1;
    };
  };

  makeBar = position:
    {
      css = "style.css";
      position = position;
      layer = "top";
      modules-center = builtins.attrNames (commonModules // desktopModules);
    }
    // desktopModules
    // commonModules;
in {
  programs.waybar = {
    enable = true;
    systemd.enable = false; # Disable systemd integration
    settings = [
      (makeBar "top")
      (makeBar "bottom")
    ];

    style = ''
      * {
        font-size: 20px;
        font-weight: bold;
        background: rgba(0, 0, 0, 0);
        text-shadow: 2px 2px 2px rgba(0, 0, 0, 0.5);
        padding: 0px;
        color: inherit;
        transition-duration: 0.2s;
      }

      #workspaces,
      #tray {
        margin-left: 20px;
        margin-right: 20px;
        color: white;
      }

      #workspaces button.visible {
        color: white;
      }
    '';
  };

  # Add Hyprland exec-once for waybar
  #wayland.windowManager.hyprland.extraConfig = ''
  #  exec-once = waybar
  #'';
}
