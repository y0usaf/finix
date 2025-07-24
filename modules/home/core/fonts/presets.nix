{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.core.fonts;
  t = lib.types;
in {
  options.home.core.fonts = {
    preset = lib.mkOption {
      type = t.enum ["fast-mono" "system" "noto" "custom"];
      default = "fast-mono";
      description = "Font preset to use";
    };

    customFonts = lib.mkOption {
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
            default = [];
            description = "Main font configurations";
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
            description = "Fallback font configurations";
          };
        };
      };
      default = {
        main = [];
        fallback = [];
      };
      description = "Custom font configurations when preset is 'custom'";
    };
  };

  config = {
    home.core.appearance.fonts =
      if cfg.preset == "fast-mono"
      then {
        main = [
          {
            package = pkgs.fastFonts;
            name = "Fast_Mono";
          }
        ];
        fallback = [
          {
            package = pkgs.noto-fonts-emoji;
            name = "Noto Color Emoji";
          }
          {
            package = pkgs.noto-fonts-cjk-sans;
            name = "Noto Sans CJK";
          }
          {
            package = pkgs.font-awesome;
            name = "Font Awesome";
          }
        ];
      }
      else if cfg.preset == "system"
      then {
        main = [
          {
            package = pkgs.dejavu_fonts;
            name = "DejaVu Sans Mono";
          }
        ];
        fallback = [
          {
            package = pkgs.noto-fonts-emoji;
            name = "Noto Color Emoji";
          }
          {
            package = pkgs.liberation_ttf;
            name = "Liberation Sans";
          }
        ];
      }
      else if cfg.preset == "noto"
      then {
        main = [
          {
            package = pkgs.noto-fonts-monospace-cjk;
            name = "Noto Sans Mono CJK";
          }
        ];
        fallback = [
          {
            package = pkgs.noto-fonts-emoji;
            name = "Noto Color Emoji";
          }
          {
            package = pkgs.noto-fonts;
            name = "Noto Sans";
          }
          {
            package = pkgs.noto-fonts-cjk-sans;
            name = "Noto Sans CJK";
          }
        ];
      }
      else {
        inherit (cfg.customFonts) main;
        inherit (cfg.customFonts) fallback;
      };
  };
}
