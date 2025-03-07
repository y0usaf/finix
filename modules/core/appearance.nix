#═══════════════════════════ 🎨 APPEARANCE MODULE 🎨 ═══════════════════════════#
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.modules) options;
  cfg = config.modules.appearance;
  t = lib.types;
in {
  options.modules.appearance = {
    enable = lib.mkEnableOption "appearance settings";

    # Font configuration using a submodule; supports both main and fallback fonts.
    fonts = lib.mkOption {
      type = t.submodule {
        options = {
          # 'main': Primary fonts specified as a list of tuples [package, fontName].
          main = lib.mkOption {
            type = t.listOf (t.tuple [t.package t.str]);
            description = "List of [package, fontName] tuples for main fonts";
          };
          # 'fallback': Fallback fonts if the main fonts are unavailable, defaults to an empty list.
          fallback = lib.mkOption {
            type = t.listOf (t.tuple [t.package t.str]);
            default = [];
            description = "List of [package, fontName] tuples for fallback fonts";
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
