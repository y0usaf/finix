#═══════════════════════════ 🎨 APPEARANCE MODULE 🎨 ═══════════════════════════#
{
  config,
  lib,
  ...
}: let
  inherit (config.modules) options;
  cfg = config.cfg.home.core.appearance;
  t = lib.types;
in {
  options.cfg.home.core.appearance = {
    enable = lib.mkEnableOption "appearance settings";

    # Font configuration using a submodule; supports both main and fallback fonts.
    fonts = lib.mkOption {
      type = t.submodule {
        options = {
          # 'main': Primary fonts specified as a list of attribute sets with 'package' and 'name' fields.
          main = lib.mkOption {
            type = t.listOf (t.submodule {
              options = {
                package = lib.mkOption {
                  type = t.package;
                  description = "Font package";
                };
                name = lib.mkOption {
                  type = t.str;
                  description = "Font name";
                };
              };
            });
            description = "List of font configurations for main fonts";
          };
          # 'fallback': Fallback fonts if the main fonts are unavailable, defaults to an empty list.
          fallback = lib.mkOption {
            type = t.listOf (t.submodule {
              options = {
                package = lib.mkOption {
                  type = t.package;
                  description = "Font package";
                };
                name = lib.mkOption {
                  type = t.str;
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

    # Base font size used as the reference for scaling other UI elements.
    baseFontSize = lib.mkOption {
      type = t.int;
      default = 12;
      description = "Base font size that other UI elements should scale from";
    };

    # The size of the mouse/system cursor.
    cursorSize = lib.mkOption {
      type = t.int;
      default = 24;
      description = "Size of the system cursor";
    };

    # The system's Display DPI setting to determine scaling and clarity.
    dpi = lib.mkOption {
      type = t.int;
      default = 96;
      description = "Display DPI setting for the system";
    };
  };

  config = lib.mkIf cfg.enable {
    # You can add any implementation details here if needed
  };
}
