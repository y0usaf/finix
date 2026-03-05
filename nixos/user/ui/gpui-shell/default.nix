{
  config,
  lib,
  pkgs,
  ...
}: let
  tomlFormat = pkgs.formats.toml {};
  tomlGenerator =
    if lib.generators ? toTOML
    then lib.generators.toTOML {}
    else (value: builtins.readFile (tomlFormat.generate "gpuishell-config" value));
in {
  options.user.ui.gpuishell = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable gpui-shell (Rust/GPUI Wayland shell)";
    };
  };

  config = lib.mkIf config.user.ui.gpuishell.enable {
    environment.systemPackages = [pkgs.gpuishell];

    usr.files.".config/gpuishell/config.toml" = {
      clobber = true;
      generator = tomlGenerator;
      value = {
        bar = {
          size = 32.0;
          position = "bottom";
          start = ["LauncherBtn" "Workspaces"];
          center = ["ActiveWindow"];
          end = ["Clock" "Battery" "Mpris" "Notifications" "Systray" "KeyboardLayout" "Settings"];
          modules = {
            clock = {
              format_horizontal = "%d/%m/%Y %H:%M";
              format_vertical = "%H\n%M";
            };
            battery = {
              show_icon = true;
              show_percentage = true;
            };
            workspaces = {
              show_icons = true;
              show_numbers = true;
            };
            sysinfo = {
              show_cpu = true;
              show_memory = true;
              show_temp = false;
            };
            mpris = {
              show_cover = true;
              max_width = 220.0;
            };
            active_window = {
              max_length = 64;
              show_app_icon = true;
            };
            keyboard_layout = {
              show_flag = false;
            };
            launcher_btn = {
              icon = "󰀻";
            };
            tray = {
              icon_size = 16.0;
            };
          };
        };
        launcher = {
          width = 600.0;
          height = 450.0;
          margin_top = 100.0;
          margin_right = 0.0;
          margin_bottom = 0.0;
          margin_left = 0.0;
          modules = {
            apps.prefix = "@";
            web.prefix = "!";
            wallpaper = {
              prefix = ";wp";
              directory = "~/Pictures/Wallpapers";
            };
            theme.prefix = "~";
          };
        };
        osd.position = "right";
        notification = {
          stack_limit = 4;
          position = "top-right";
        };
        control_center.power_actions = {
          sleep = "systemctl suspend";
          reboot = "systemctl reboot";
          poweroff = "systemctl poweroff";
        };
      };
    };
  };
}
