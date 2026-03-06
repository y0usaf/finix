{lib, ...}: {
  imports = [
    ./wallust
  ];

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
