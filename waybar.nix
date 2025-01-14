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
          "custom/ram"
          "custom/cpu_temp"
          "custom/gpu_temp"
          "battery"
          "tray"
        ];
        "include" = ["$XDG_CONFIG_HOME/waybar/$(cat /etc/hostname)"];
      }
      {
        "css" = "style.css";
        "position" = "bottom";
        "layer" = "top";
        "modules-center" = [
          "hyprland/workspaces"
          "clock"
          "custom/ram"
          "custom/cpu_temp"
          "custom/gpu_temp"
          "battery"
          "tray"
        ];
        "include" = ["$XDG_CONFIG_HOME/waybar/$(cat /etc/hostname)"];
      }
    ];

    # Module configurations
    settings.clock = {
      "format" = "{:%H:%M:%OS %d/%m }| ";
      "interval" = 1;
    };

    settings."custom/ram" = {
      "format" = "RAM: {} MB | ";
      "exec" = "free -m | awk '/^Mem:/{print $3}'";
      "interval" = 1;
    };

    settings."custom/gpu_temp" = {
      "format" = "GPU: {}°C";
      "exec" = "sudo nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader";
      "interval" = 1;
    };

    settings."custom/cpu_temp" = {
      "format" = "CPU: {} | ";
      "exec" = "sensors | grep 'Tctl:' | awk '{print $2}'";
      "interval" = 1;
    };

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
    nvidia-smi # For GPU temperature
    cava # For audio visualization
  ];
}
