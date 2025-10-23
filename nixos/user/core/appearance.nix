{
  config,
  lib,
  ...
}: {
  options.user.appearance = {
    fonts = lib.mkOption {
      type = lib.types.submodule {
        options = {
          main = lib.mkOption {
            type = lib.types.listOf (lib.types.submodule {
              options = {
                package = lib.mkOption {
                  type = lib.types.package;
                  description = "Font package";
                };
                name = lib.mkOption {
                  type = lib.types.str;
                  description = "Font name";
                };
              };
            });
            description = "List of font configurations for main fonts";
          };
          fallback = lib.mkOption {
            type = lib.types.listOf (lib.types.submodule {
              options = {
                package = lib.mkOption {
                  type = lib.types.package;
                  description = "Font package";
                };
                name = lib.mkOption {
                  type = lib.types.str;
                  description = "Font name";
                };
              };
            });
            default = [];
            description = "List of font configurations for fallback fonts";
          };
        };
      };
      description = "System font configuration";
    };
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
  };
}
