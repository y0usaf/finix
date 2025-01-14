{
  config,
  pkgs,
  lib,
  globals,
  ...
}: {
  programs.waybar = {
    enable = true;
    systemd = {
      enable = true;
      target = "hyprland-session.target";
    };

    settings = [
      {
        "css" = "style.css";
        "position" = "top";
        "layer" = "top";
        "modules-center" =
          [
            "hyprland/workspaces"
            "clock"
          ]
          ++ lib.optionals (globals.hostname == "y0usaf-desktop") [
            "custom/ram"
          ]
          ++ [
            "battery"
            "tray"
          ];

        # Basic modules for all hosts
        "clock" = {
          "format" = "{:%H:%M:%OS %d/%m }| ";
          "interval" = 1;
        };

        # Desktop-specific modules
        "custom/ram" = lib.mkIf (globals.hostname == "y0usaf-desktop") {
          "format" = "RAM: {} MB | ";
          "exec" = "free -m | awk '/^Mem:/{print $3}'";
          "interval" = 1;
        };
      }
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
}
