{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.ui.niri;
  inherit (config.home.core) defaults;
  agsEnabled = config.home.ui.ags.enable or false;
  
  # Import local generators
  generators = import ../../../../lib/generators.nix {inherit lib;};

  # Default configuration merged with user settings
  defaultSettings = {
    prefer-no-csd = true;

    spawn-at-startup =
      [
        "${pkgs.xwayland-satellite}/bin/xwayland-satellite"
        "sh -c \"swaybg -i $(find ${config.home.directories.wallpapers.static.path} -type f | shuf -n 1) -m fill\""
      ]
      ++ lib.optional agsEnabled "${pkgs.ags}/bin/ags run /home/${config.user.name}/.config/ags/bar-overlay.tsx";

    input = {
      keyboard = {
        xkb = {
          layout = "us";
        };
      };
      touchpad = {
        tap = true;
        dwt = true;
        natural-scroll = true;
        accel-speed = 0.0;
      };
      mouse = {
        accel-speed = 0.0;
      };
      focus-follows-mouse = {
        _args = ["max-scroll-amount=\"0%\""];
      };
      mod-key = "Alt";
    };

    output = {
      "DP-4" = {
        mode = "5120x1440@239.761";
        position = {
          x = 0;
          y = 0;
        };
      };
      "DP-2" = {
        mode = "5120x1440@239.761";
        position = {
          x = 0;
          y = 0;
        };
      };
      "HDMI-A-2" = {
        mode = "1920x1080@60.000";
        position = {
          x = 5120;
          y = 0;
        };
      };
    };

    layout = {
      gaps = 10;
      center-focused-column = "never";
      default-column-display = "tabbed";
      default-column-width = {
        proportion = 0.5;
      };
      preset-column-widths = [
        {proportion = 0.33333;}
        {proportion = 0.5;}
        {proportion = 0.66667;}
      ];

      border = {
        width = 0.5;
        active-color = "#ffffff";
        inactive-color = "#333333";
      };

      focus-ring = {
        width = 0.5;
        active-color = "#ffffff";
        inactive-color = "#333333";
      };

      tab-indicator = {
        width = 4;
        gap = 6;
        active-color = "#ffffff";
        inactive-color = "#666666";
        position = "left";
      };
    };

    hotkey-overlay = {};

    animations = {
      slowdown = 1.0;
      window-open = {
        duration-ms = 150;
        curve = "ease-out-expo";
      };
      window-close = {
        duration-ms = 150;
        curve = "ease-out-expo";
      };
    };

    window-rule = {
      _children = [
        {
          match = {
            _props = {app-id = "foot";};
          };
          opacity = 1.0;
        }
        {
          match = {
            _props = {app-id = "launcher";};
          };
          open-floating = true;
        }
      ];
    };

    binds = {
      "Mod+Shift+Slash" = {show-hotkey-overlay = null;};

      "Mod+T" = {spawn = defaults.terminal;};
      "Super+R" = {
        spawn = [
          "foot"
          "-a"
          "launcher"
          "${config.user.configDirectory}/scripts/sway-launcher-desktop.sh"
        ];
      };

      "Mod+Q" = {close-window = null;};
      "Mod+Shift+F" = {fullscreen-window = null;};
      "Mod+F" = {maximize-column = null;};
      "Super+F" = {toggle-windowed-fullscreen = null;};
      "Mod+Space" = {center-column = null;};
      "Super+Space" = {toggle-window-floating = null;};

      # Navigation
      "Mod+Left" = {focus-column-left = null;};
      "Mod+Right" = {focus-column-right = null;};
      "Mod+Up" = {focus-window-up = null;};
      "Mod+Down" = {focus-window-down = null;};
      "Mod+H" = {focus-column-left = null;};
      "Mod+L" = {focus-column-right = null;};
      "Mod+J" = {focus-window-down = null;};
      "Mod+K" = {focus-window-up = null;};

      # Moving windows
      "Mod+Shift+Left" = {move-column-left = null;};
      "Mod+Shift+Right" = {move-column-right = null;};
      "Mod+Shift+Up" = {move-window-up = null;};
      "Mod+Shift+Down" = {move-window-down = null;};
      "Mod+Shift+H" = {move-column-left = null;};
      "Mod+Shift+L" = {move-column-right = null;};
      "Mod+Shift+J" = {move-window-down = null;};
      "Mod+Shift+K" = {move-window-up = null;};

      # Workspaces
      "Mod+Page_Up" = {focus-workspace-up = null;};
      "Mod+Page_Down" = {focus-workspace-down = null;};
      "Mod+U" = {focus-workspace-up = null;};
      "Mod+I" = {focus-workspace-down = null;};
      "Super+1" = {focus-workspace = 1;};
      "Super+2" = {focus-workspace = 2;};
      "Super+3" = {focus-workspace = 3;};
      "Super+4" = {focus-workspace = 4;};
      "Super+5" = {focus-workspace = 5;};
      "Super+6" = {focus-workspace = 6;};
      "Super+7" = {focus-workspace = 7;};
      "Super+8" = {focus-workspace = 8;};
      "Super+9" = {focus-workspace = 9;};

      # Moving to workspaces
      "Mod+Ctrl+Page_Up" = {move-column-to-workspace-up = null;};
      "Mod+Ctrl+Page_Down" = {move-column-to-workspace-down = null;};
      "Mod+Ctrl+U" = {move-column-to-workspace-up = null;};
      "Mod+Ctrl+I" = {move-column-to-workspace-down = null;};
      "Super+Shift+1" = {move-column-to-workspace = 1;};
      "Super+Shift+2" = {move-column-to-workspace = 2;};
      "Super+Shift+3" = {move-column-to-workspace = 3;};
      "Super+Shift+4" = {move-column-to-workspace = 4;};
      "Super+Shift+5" = {move-column-to-workspace = 5;};
      "Super+Shift+6" = {move-column-to-workspace = 6;};
      "Super+Shift+7" = {move-column-to-workspace = 7;};
      "Super+Shift+8" = {move-column-to-workspace = 8;};
      "Super+Shift+9" = {move-column-to-workspace = 9;};

      # Column management
      "Mod+R" = {switch-preset-column-width = null;};
      "Mod+Shift+R" = {switch-preset-window-height = null;};
      "Mod+Comma" = {consume-window-into-column = null;};
      "Mod+Period" = {expel-window-from-column = null;};
      "Mod+BracketLeft" = {consume-or-expel-window-left = null;};
      "Mod+BracketRight" = {consume-or-expel-window-right = null;};

      # Screenshots
      "Mod+G" = {spawn = "sh -c \"grim -g \\\"$(slurp -d)\\\" - | wl-copy -t image/png\"";};
      "Mod+Shift+G" = {spawn = "sh -c \"grim - | wl-copy -t image/png\"";};

      # System
      "Mod+Shift+E" = {quit = null;};
      "Mod+O" = {toggle-overview = null;};

      # Applications
      "Mod+1" = {spawn = defaults.ide;};
      "Mod+2" = {spawn = defaults.browser;};
      "Mod+3" = {spawn = "vesktop";};
      "Mod+4" = {spawn = "steam";};
      "Mod+5" = {spawn = "obs";};

      "Mod+E" = {spawn = defaults.fileManager;};
      "Mod+Shift+O" = {spawn = "${defaults.terminal} -e ${defaults.editor}";};

      # Change wallpaper
      "Mod+Shift+C" = {spawn = "sh -c \"killall swaybg; swaybg -i $(find ${config.home.directories.wallpapers.static.path} -type f | shuf -n 1) -m fill &\"";};
    };

    debug = {
      wait-for-frame-completion-in-pipewire = null;
      dbus-interfaces-in-non-session-instances = null;
    };

    environment = {
      DISPLAY = ":0";
    };
  };

  # Merge default settings with user settings
  finalSettings = lib.recursiveUpdate defaultSettings cfg.settings;
in {
  config = lib.mkIf cfg.enable {
    hjem.users.${config.user.name} = {
      packages = [
        pkgs.niri
        pkgs.grim
        pkgs.slurp
        pkgs.wl-clipboard
        pkgs.jq
        pkgs.swaybg
      ];
      files = {
        ".config/niri/config.kdl" = {
          text = generators.toKDL {} finalSettings 
            + lib.optionalString (cfg.extraConfig != "") ("\n\n" + cfg.extraConfig);
          clobber = true;
        };
      };
    };
  };
}
