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
  generators = import ../../../../lib/generators {inherit lib;};

  # Default configuration merged with user settings
  defaultSettings = {
    prefer-no-csd = {};

    spawn-at-startup =
      [
        ["${pkgs.xwayland-satellite}/bin/xwayland-satellite"]
        ["sh" "-c" "swaybg -i $(find ${config.home.directories.wallpapers.static.path} -type f | shuf -n 1) -m fill"]
      ]
      ++ lib.optional agsEnabled ["${pkgs.ags}/bin/ags" "run" "/home/${config.user.name}/.config/ags/bar-overlay.tsx"];

    input = {
      keyboard = {
        xkb = {
          layout = "us";
        };
      };
      touchpad = {
        tap = {};
        dwt = {};
        natural-scroll = {};
        accel-speed = 0.0;
      };
      mouse = {
        accel-speed = 0.0;
      };
      focus-follows-mouse = {
        _props = {"max-scroll-amount" = "0%";};
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
      preset-column-widths = {
        _children = [
          {proportion = 0.33333;}
          {proportion = 0.5;}
          {proportion = 0.66667;}
        ];
      };

      border = {
        width = 1;
        active-color = "ffffff";
        inactive-color = "#000000";
      };

      focus-ring = {
        off = {};
      };

      tab-indicator = {
        width = 10;
        gap = -5;
        length = {
          _props = {
            "total-proportion" = 0.01;
          };
        };
        active-color = "#ffffff";
        inactive-color = "aaaaaa";
        position = "bottom";
      };
    };

    hotkey-overlay = {};

    # Using extraConfig for proper window-rule syntax until KDL generator supports multiple root-level nodes
    window-rule = {}; # Placeholder to prevent missing key errors

    binds = {
      "Mod+Shift+Slash" = {show-hotkey-overlay = {};};

      "Mod+T" = {spawn = defaults.terminal;};
      "Super+R" = {
        spawn = [
          "foot"
          "-a"
          "launcher"
          "${config.user.configDirectory}/scripts/sway-launcher-desktop.sh"
        ];
      };

      "Mod+Q" = {close-window = {};};
      "Mod+Shift+F" = {fullscreen-window = {};};
      "Mod+F" = {maximize-column = {};};
      "Super+F" = {toggle-windowed-fullscreen = {};};
      "Mod+Space" = {center-column = {};};
      "Super+Space" = {toggle-window-floating = {};};

      # Navigation
      "Mod+Left" = {focus-column-left = {};};
      "Mod+Right" = {focus-column-right = {};};
      "Mod+Up" = {focus-window-up = {};};
      "Mod+Down" = {focus-window-down = {};};
      "Mod+H" = {focus-column-left = {};};
      "Mod+L" = {focus-column-right = {};};
      "Mod+J" = {focus-window-down = {};};
      "Mod+K" = {focus-window-up = {};};

      # Moving windows
      "Mod+Shift+Left" = {move-column-left = {};};
      "Mod+Shift+Right" = {move-column-right = {};};
      "Mod+Shift+Up" = {move-window-up = {};};
      "Mod+Shift+Down" = {move-window-down = {};};
      "Mod+Shift+H" = {move-column-left = {};};
      "Mod+Shift+L" = {move-column-right = {};};
      "Mod+Shift+J" = {move-window-down = {};};
      "Mod+Shift+K" = {move-window-up = {};};

      # Workspaces
      "Mod+Page_Up" = {focus-workspace-up = {};};
      "Mod+Page_Down" = {focus-workspace-down = {};};
      "Mod+U" = {focus-workspace-up = {};};
      "Mod+I" = {focus-workspace-down = {};};
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
      "Mod+Ctrl+Page_Up" = {move-column-to-workspace-up = {};};
      "Mod+Ctrl+Page_Down" = {move-column-to-workspace-down = {};};
      "Mod+Ctrl+U" = {move-column-to-workspace-up = {};};
      "Mod+Ctrl+I" = {move-column-to-workspace-down = {};};
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
      "Mod+R" = {switch-preset-column-width = {};};
      "Mod+Shift+R" = {switch-preset-window-height = {};};
      "Mod+Comma" = {consume-window-into-column = {};};
      "Mod+Period" = {expel-window-from-column = {};};
      "Mod+BracketLeft" = {consume-or-expel-window-left = {};};
      "Mod+BracketRight" = {consume-or-expel-window-right = {};};

      # Screenshots
      "Mod+G" = {spawn = ["sh" "-c" "grim -g $(slurp) - | wl-copy"];};
      "Mod+Shift+G" = {spawn = ["sh" "-c" "grim - | wl-copy"];};

      # System
      "Mod+Shift+E" = {quit = {};};
      "Mod+O" = {toggle-overview = {};};

      # Applications
      "Mod+1" = {spawn = defaults.ide;};
      "Mod+2" = {spawn = defaults.browser;};
      "Mod+3" = {spawn = "vesktop";};
      "Mod+4" = {spawn = "steam";};
      "Mod+5" = {spawn = "obs";};

      "Mod+E" = {spawn = defaults.fileManager;};
      "Mod+Shift+O" = {spawn = "${defaults.terminal} -e ${defaults.editor}";};

      # Change wallpaper
      "Mod+Shift+C" = {spawn = ["sh" "-c" "killall swaybg; swaybg -i $(find ${config.home.directories.wallpapers.static.path} -type f | shuf -n 1) -m fill &"];};
    };

    debug = {
      wait-for-frame-completion-in-pipewire = {};
      dbus-interfaces-in-non-session-instances = {};
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
          clobber = true;
          generator = generators.toNiriconf;
          value =
            finalSettings
            // lib.optionalAttrs (cfg.extraConfig != "") {
              _extraConfig = cfg.extraConfig;
            };
        };
      };
    };
  };
}
