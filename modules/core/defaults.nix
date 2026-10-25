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
    glass = {
      opacity = lib.mkOption {
        type = lib.types.numbers.between 0 1;
        default = 0;
        description = "Background opacity of terminals, GTK windows and the tomoe rail; the compositor's blur shows through the rest.";
      };
      passes = lib.mkOption {
        type = lib.types.ints.positive;
        default = 3;
        description = "Blur passes behind glass surfaces.";
      };
      offset = lib.mkOption {
        type = lib.types.ints.positive;
        default = 4;
        description = "Blur sample offset in pixels.";
      };
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
