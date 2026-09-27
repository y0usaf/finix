{lib, ...}: {
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
}
