{lib, ...}: {
  # Appearance options (DPI, animations, etc.)
  options.user.appearance = {
    termFontSize = lib.mkOption {
      type = lib.types.int;
      default = 12;
      description = "Font size used by terminal emulators (e.g. foot)";
    };
    gtkFontSize = lib.mkOption {
      type = lib.types.int;
      default = 12;
      description = "Font size used by GTK applications";
    };
    cursorSize = lib.mkOption {
      type = lib.types.int;
      default = 24;
      description = "Size of the system cursor";
    };
    cursorTheme = lib.mkOption {
      type = lib.types.enum ["popucom" "deepin"];
      default = "popucom";
      description = "Cursor theme to use (popucom = animated Popucom theme, deepin = Deepin cursor theme)";
    };
    cursorColor = lib.mkOption {
      type = lib.types.enum ["pink" "green" "blue" "yellow" "red" "orange" "cyan" "purple" "grey" "black" "inverted"];
      default = "pink";
      description = "Color variant for the Popucom animated cursor theme";
    };
    dpi = lib.mkOption {
      type = lib.types.int;
      default = 96;
      description = "Display DPI setting for the system";
    };
    animations = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether to enable animations globally across all applications";
          };
        };
      };
      default = {};
      description = "Global animation configuration for the system";
    };
    opacity = lib.mkOption {
      type = lib.types.float;
      default = 0.1;
      description = "Global UI opacity setting (0.0 = fully transparent, 1.0 = fully opaque)";
    };
  };
}
