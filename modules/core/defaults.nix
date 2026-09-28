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
      default = "monstar";
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
    dpi = lib.mkOption {
      type = lib.types.int;
      default = 96;
      description = "Display DPI setting for the system";
    };
  };

  options.user.paths = {
    steam = lib.mkOption {
      type = lib.types.str;
      default = ".local/share/Steam";
      description = "Steam's directory, relative to the home directory.";
    };
  };

  config.environment.variables = {
    TERMINAL = config.user.defaults.terminal;
    BROWSER = config.user.defaults.browser;
    EDITOR = "nvim";
  };
}
