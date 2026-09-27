{
  config,
  lib,
  ...
}: {
  options.user.defaults = {
    browser = lib.mkOption {
      type = lib.types.str;
      default = "librewolf";
      description = "Default web browser";
    };
    terminal = lib.mkOption {
      type = lib.types.str;
      default = "foot";
      description = "Default terminal emulator";
    };
    launcher = lib.mkOption {
      type = lib.types.str;
      default = "monstar --app-id=launcher -e ~/.config/scripts/tui-launcher.sh";
      description = "Default application launcher";
    };
  };

  options.user.appearance = {
    termFontSize = lib.mkOption {
      type = lib.types.int;
      default = 12;
      description = "Font size used by terminal emulators (e.g. foot)";
    };
    hyprcursorSize = lib.mkOption {
      type = lib.types.int;
      default = 24;
      description = "Base Hyprcursor size at user.appearance.dpi.";
    };
    dpi = lib.mkOption {
      type = lib.types.int;
      default = 96;
      description = "Display DPI setting for the system";
    };
  };

  options.user.paths = {
    steam = lib.mkOption {
      type = lib.types.str;
      default = "${config.user.homeDirectory}/.local/share/Steam";
      description = "Directory for Steam.";
    };
    wallpapers = lib.mkOption {
      type = lib.types.str;
      default = "${config.user.homeDirectory}/DCIM/Wallpapers";
      description = "Wallpaper directory for static images.";
    };
  };

  config.environment.variables = {
    TERMINAL = config.user.defaults.terminal;
    BROWSER = config.user.defaults.browser;
    EDITOR = "nvim";
  };
}
