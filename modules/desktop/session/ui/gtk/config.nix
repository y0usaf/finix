{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.user) ui appearance;
  gtkCfg = ui.gtk;
  gtkScale = gtkCfg.scale;
  cursorSize = builtins.floor (24 * gtkScale);
  cursorSizeStr = builtins.replaceStrings [".0"] [""] (toString cursorSize);
  toINI = lib.generators.toINI {};
  inherit (appearance) gtkFontSize;
  inherit (ui.fonts) mainFontName;
  shadowSize = "0.05rem";
  shadowRadius = "0.05rem";
  shadowColor = "rgba(0, 0, 0, 0.3)";
  backgroundColor = "transparent";
in {
  options.user.ui.gtk = {
    enable = lib.mkEnableOption "GTK theming and configuration using bayt";
    scale = lib.mkOption {
      type = lib.types.float;
      default = 1.0;
      description = "Scaling factor for GTK applications (e.g., 1.0, 1.25, 1.5, 2.0)";
    };
  };

  config = lib.mkIf gtkCfg.enable {
    environment.systemPackages = [
      pkgs.gtk3
      pkgs.gtk4
    ];
    bayt.users."${config.user.name}" = {
      files =
        {
          ".config/gtk-3.0/settings.ini" = {
            generator = toINI;
            value = {
              Settings = {
                gtk-application-prefer-dark-theme = 1;
                gtk-cursor-theme-name = "SSB-x11";
                gtk-cursor-theme-size = toString cursorSize;
                gtk-font-name = "${mainFontName} ${toString gtkFontSize}";
                gtk-xft-antialias = 1;
                gtk-xft-dpi = toString appearance.dpi;
                gtk-xft-hinting = 1;
                gtk-xft-hintstyle = "hintslight";
                gtk-xft-rgba = "rgb";
              };
            };
          };
          ".config/gtk-3.0/gtk.css" = {
            text = ''
              /* Global element styling */
              * {
                font-family: "${mainFontName}";
                color: white;
                background: ${backgroundColor};
                outline-width: 0;
                outline-offset: 0;
                text-shadow: ${lib.concatStringsSep ",\n" (lib.concatLists (lib.genList
                (_: [
                  "${shadowSize} 0 ${shadowRadius} ${shadowColor}"
                  "-${shadowSize} 0 ${shadowRadius} ${shadowColor}"
                  "0 ${shadowSize} ${shadowRadius} ${shadowColor}"
                  "0 -${shadowSize} ${shadowRadius} ${shadowColor}"
                  "${shadowSize} ${shadowSize} ${shadowRadius} ${shadowColor}"
                  "-${shadowSize} ${shadowSize} ${shadowRadius} ${shadowColor}"
                  "${shadowSize} -${shadowSize} ${shadowRadius} ${shadowColor}"
                  "-${shadowSize} -${shadowSize} ${shadowRadius} ${shadowColor}"
                ])
                4))};
              }
              /* Hover state for all elements */
              *:hover {
                background: rgba(100, 149, 237, 0.1);
              }
              /* Selected state for all elements */
              *:selected {
                background: rgba(100, 149, 237, 0.5);
              }
              /* Button styling */
              button {
                border-radius: 0.15rem;
                min-height: 1rem;
                padding: 0.05rem 0.25rem;
              }
              /* Menu background styling */
              menu {
                background: ${backgroundColor};
              }
            '';
          };
          ".config/gtk-3.0/bookmarks" = {
            text = lib.concatStringsSep "\n" config.user.paths.bookmarks;
          };
          ".config/gtk-4.0/settings.ini" = {
            generator = toINI;
            value = {
              Settings = {
                gtk-application-prefer-dark-theme = 1;
                gtk-cursor-theme-name = "SSB-x11";
                gtk-cursor-theme-size = toString cursorSize;
                gtk-font-name = "${mainFontName} ${toString gtkFontSize}";
              };
            };
          };
        }
        // lib.optionalAttrs (lib.attrByPath ["user" "shell" "zsh" "enable"] false config) {
          ".config/zsh/.zshenv" = {
            text = lib.mkAfter ''
              export XCURSOR_SIZE="${cursorSizeStr}"
              export GDK_DPI_SCALE="${toString gtkScale}"
            '';
          };
        }
        // lib.optionalAttrs (lib.attrByPath ["user" "shell" "nushell" "enable"] false config) {
          ".config/nushell/env.nu" = {
            text = lib.mkAfter ''
              $env.XCURSOR_SIZE = "${cursorSizeStr}"
              $env.GDK_DPI_SCALE = "${toString gtkScale}"
            '';
          };
        };
    };
  };
}
