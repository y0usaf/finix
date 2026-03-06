{
  lib,
  config,
  ...
}: {
  imports = [
    ./wallust
  ];

  # Appearance options (DPI, animations, etc.)
  options.user.appearance = {
    baseFontSize = lib.mkOption {
      type = lib.types.int;
      default = 12;
      description = "Base font size that other UI elements should scale from";
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
    scaledFontSize = lib.mkOption {
      type = lib.types.int;
      description = "Font size scaled proportionally from baseFontSize at 96 DPI reference";
    };
  };

  config.user.appearance.scaledFontSize = builtins.floor (config.user.appearance.baseFontSize * config.user.appearance.dpi / 96);
}
