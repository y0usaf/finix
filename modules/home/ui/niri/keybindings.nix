{
  config,
  lib,
  ...
}: let
  cfg = config.home.ui.niri;
  inherit (config.home.core) defaults;
in {
  config = lib.mkIf cfg.enable {
    home.ui.niri.settings.binds = {
      # System & Help
      "Mod+Shift+Slash" = {show-hotkey-overlay = {};};
      "Mod+Shift+E" = {quit = {};};
      "Mod+O" = {toggle-overview = {};};

      # Core Applications
      "Mod+T" = {spawn = defaults.terminal;};
      "Super+R" = {
        spawn = [
          "foot"
          "-a"
          "launcher"
          "${config.user.configDirectory}/scripts/tui-launcher.sh"
        ];
      };
      "Mod+E" = {spawn = defaults.fileManager;};
      "Super+Shift+O" = {spawn = "${defaults.terminal} -e ${defaults.editor}";};

      # Window Management
      "Mod+Q" = {close-window = {};};
      "Mod+F" = {maximize-column = {};};
      "Mod+Shift+F" = {fullscreen-window = {};};
      "Super+F" = {toggle-windowed-fullscreen = {};};
      "Mod+Space" = {center-column = {};};
      "Super+Space" = {toggle-window-floating = {};};

      # Navigation - Focus
      "Mod+H" = {focus-column-left = {};};
      "Mod+L" = {focus-column-right = {};};
      "Mod+J" = {focus-window-down = {};};
      "Mod+K" = {focus-window-up = {};};
      "Mod+Left" = {focus-column-left = {};};
      "Mod+Right" = {focus-column-right = {};};
      "Mod+Up" = {focus-window-up = {};};
      "Mod+Down" = {focus-window-down = {};};

      # Window Movement
      "Mod+Shift+H" = {move-column-left = {};};
      "Mod+Shift+L" = {move-column-right = {};};
      "Mod+Shift+J" = {move-window-down = {};};
      "Mod+Shift+K" = {move-window-up = {};};
      "Mod+Shift+Left" = {move-column-left = {};};
      "Mod+Shift+Right" = {move-column-right = {};};
      "Mod+Shift+Up" = {move-window-up = {};};
      "Mod+Shift+Down" = {move-window-down = {};};

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

      # Applications
      "Mod+1" = {spawn = defaults.ide;};
      "Mod+2" = {spawn = defaults.browser;};
      "Mod+3" = {spawn = "vesktop";};
      "Mod+4" = {spawn = "steam";};
      "Mod+5" = {spawn = "obs";};

      # Screenshots & Media
      "Mod+G" = {screenshot = {};};
      "Mod+Shift+G" = {screenshot-screen = {};};

      # Utilities
      "Alt+grave" = {spawn = ["bash" "-c" "niri msg pick-color | grep Hex: | cut -d' ' -f2 | wl-copy"];};
      "Mod+Shift+C" = {spawn = ["sh" "-c" "killall swaybg; swaybg -i $(find ${config.home.directories.wallpapers.static.path} -type f | shuf -n 1) -m fill &"];};

      # Monitor controls
      "Mod+6" = {spawn = ["sh" "-c" "niri msg output DP-4 on; niri msg output DP-2 on; niri msg output HDMI-A-2 on"];};
      "Mod+7" = {spawn = ["sh" "-c" "niri msg output DP-4 off; niri msg output DP-2 off; niri msg output HDMI-A-2 off"];};
    };
  };
}
