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
        "modules-center" = [
          "hyprland/workspaces"
          "clock"
          "cava"
        ] ++ lib.optionals (globals.hostname == "y0usaf-desktop") [
          "custom/ram"
          "custom/cpu_temp"
          "custom/gpu_temp"
        ] ++ [
          "battery"
          "tray"
        ];

        # Basic modules for all hosts
        "clock" = {
          "format" = "{:%H:%M:%OS %d/%m }| ";
          "interval" = 1;
        };

        "cava" = {
          "framerate" = 240;
          "autosens" = 0;
          "sensitivity" = 10;
          "bars" = 52;
          "lower_cutoff_freq" = 50;
          "higher_cutoff_freq" = 10000;
          "method" = "pulse";
          "source" = "auto";
          "stereo" = true;
          "reverse" = false;
          "bar_delimiter" = 0;
          "monstercat" = true;
          "waves" = false;
          "noise_reduction" = 0.7;
          "input_delay" = 0;
          "format-icons" = ["▁" "▂" "▃" "▄" "▅" "▆" "▇" "█"];
          "actions" = {
            "on-click-right" = "mode";
          };
        };
      } // lib.optionalAttrs (globals.hostname == "y0usaf-desktop") {
        "custom/ram" = {
          "format" = "RAM: {} MB | ";
          "exec" = "free -m | awk '/^Mem:/{print $3}'";
          "interval" = 1;
        };

        "custom/gpu_temp" = {
          "format" = "GPU: {}°C";
          "exec" = "${pkgs.nvidia-settings}/bin/nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader";
          "interval" = 1;
        };

        "custom/cpu_temp" = {
          "format" = "CPU: {} | ";
          "exec" = "sensors | grep 'Tctl:' | awk '{print $2}'";
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

  # Ensure required packages are installed for the custom scripts
  home.packages = with pkgs; [
    cava # For audio visualization
  ] ++ lib.optionals (globals.hostname == "y0usaf-desktop") [
    lm_sensors # For CPU temperature
  ];
}
