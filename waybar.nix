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
          "custom/ram"
          "custom/cpu_temp"
          "custom/gpu_temp"
          "battery"
          "tray"
        ];
        "include" = ["$XDG_CONFIG_HOME/waybar/$(cat /etc/hostname)"];

        # Module configurations
        "clock" = {
          "format" = "{:%H:%M:%OS %d/%m }| ";
          "interval" = 1;
        };

        "custom/ram" = {
          "format" = "RAM: {} MB | ";
          "exec" = "free -m | awk '/^Mem:/{print $3}'";
          "interval" = 1;
        };

        "custom/gpu_temp" = {
          "format" = "GPU: {}°C";
          "exec" = "${pkgs.polkit}/bin/pkexec ${pkgs.nvidia-utils}/bin/nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader";
          "interval" = 1;
        };

        "custom/cpu_temp" = {
          "format" = "CPU: {} | ";
          "exec" = "sensors | grep 'Tctl:' | awk '{print $2}'";
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
      }
      {
        "css" = "style.css";
        "position" = "bottom";
        "layer" = "top";
        "modules-center" = [
          "hyprland/workspaces"
          "clock"
          "cava"
          "custom/ram"
          "custom/cpu_temp"
          "custom/gpu_temp"
          "battery"
          "tray"
        ];
        "include" = ["$XDG_CONFIG_HOME/waybar/$(cat /etc/hostname)"];

        # Module configurations (same as top bar)
        "clock" = {
          "format" = "{:%H:%M:%OS %d/%m }| ";
          "interval" = 1;
        };

        "custom/ram" = {
          "format" = "RAM: {} MB | ";
          "exec" = "free -m | awk '/^Mem:/{print $3}'";
          "interval" = 1;
        };

        "custom/gpu_temp" = {
          "format" = "GPU: {}°C";
          "exec" = "${pkgs.polkit}/bin/pkexec ${pkgs.nvidia-utils}/bin/nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader";
          "interval" = 1;
        };

        "custom/cpu_temp" = {
          "format" = "CPU: {} | ";
          "exec" = "sensors | grep 'Tctl:' | awk '{print $2}'";
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
    lm_sensors # For CPU temperature
    cava # For audio visualization
  ];
}
