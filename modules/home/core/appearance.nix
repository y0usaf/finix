{
  config,
  lib,
  ...
}: let
  cfg = config.home.core.appearance;
  t = lib.types;
in {
  options.home.core.appearance = {
    enable = lib.mkEnableOption "appearance settings";
    fonts = lib.mkOption {
      type = t.submodule {
        options = {
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
    baseFontSize = lib.mkOption {
      type = t.int;
      default = 12;
      description = "Base font size that other UI elements should scale from";
    };
    cursorSize = lib.mkOption {
      type = t.int;
      default = 24;
      description = "Size of the system cursor";
    };
    dpi = lib.mkOption {
      type = t.int;
      default = 96;
      description = "Display DPI setting for the system";
    };
    animations = lib.mkOption {
      type = t.submodule {
        options = {
          enable = lib.mkOption {
            type = t.bool;
            default = true;
            description = "Whether to enable animations globally across all applications";
          };
        };
      };
      default = {};
      description = "Global animation configuration for the system";
    };
    opacity = lib.mkOption {
      type = t.float;
      default = 0.1;
      description = "Global UI opacity setting (0.0 = fully transparent, 1.0 = fully opaque)";
    };
  };
  config =
    lib.mkIf cfg.enable {
    };
}
