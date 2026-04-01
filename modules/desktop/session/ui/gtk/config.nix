{
  config,
  lib,
  pkgs,
  ...
}: let
  zshEnabled = lib.attrByPath ["user" "shell" "zsh" "enable"] false config;
  nushellEnabled = lib.attrByPath ["user" "shell" "nushell" "enable"] false config;
  inherit (config) user;
  shadowSize = "0.05rem";
  shadowRadius = "0.05rem";
  shadowColor = "rgba(0, 0, 0, 0.3)";
  backgroundColor = "rgba(0, 0, 0, ${toString (user.appearance.opacity / 3)})";
  gtkCss = ''
    /* Global element styling */
    * {
      font-family: "${user.ui.fonts.mainFontName}";
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
in {
  config = lib.mkIf config.user.ui.gtk.enable {
    environment.systemPackages = [
      pkgs.gtk3
      pkgs.gtk4
    ];
    bayt.users."${config.user.name}" = {
      files =
        {
          ".config/gtk-3.0/settings.ini" = {
            clobber = true;
            generator = lib.generators.toINI {};
            value = {
              Settings = {
                gtk-application-prefer-dark-theme = 1;
                gtk-cursor-theme-name = "SSB-x11";
                gtk-cursor-theme-size = toString (builtins.floor (24 * config.user.ui.gtk.scale));
                gtk-font-name = "${config.user.ui.fonts.mainFontName} ${toString config.user.appearance.gtkFontSize}";
                gtk-xft-antialias = 1;
                gtk-xft-dpi = toString config.user.appearance.dpi;
                gtk-xft-hinting = 1;
                gtk-xft-hintstyle = "hintslight";
                gtk-xft-rgba = "rgb";
              };
            };
          };
          ".config/gtk-3.0/gtk.css" = {
            clobber = true;
            text = gtkCss;
          };
          ".config/gtk-3.0/bookmarks" = {
            clobber = true;
            text = lib.concatStringsSep "\n" config.user.paths.bookmarks;
          };
          ".config/gtk-4.0/settings.ini" = {
            clobber = true;
            generator = lib.generators.toINI {};
            value = {
              Settings = {
                gtk-application-prefer-dark-theme = 1;
                gtk-cursor-theme-name = "SSB-x11";
                gtk-cursor-theme-size = toString (builtins.floor (24 * config.user.ui.gtk.scale));
                gtk-font-name = "${config.user.ui.fonts.mainFontName} ${toString config.user.appearance.gtkFontSize}";
              };
            };
          };
        }
        // lib.optionalAttrs zshEnabled {
          ".config/zsh/.zshenv" = {
            clobber = true;
            text = lib.mkAfter ''
              export XCURSOR_SIZE="${builtins.replaceStrings [".0"] [""] (toString (builtins.floor (24 * config.user.ui.gtk.scale)))}"
              export GDK_DPI_SCALE="${toString config.user.ui.gtk.scale}"
            '';
          };
        }
        // lib.optionalAttrs nushellEnabled {
          ".config/nushell/env.nu" = {
            clobber = true;
            text = lib.mkAfter ''
              $env.XCURSOR_SIZE = "${builtins.replaceStrings [".0"] [""] (toString (builtins.floor (24 * config.user.ui.gtk.scale)))}"
              $env.GDK_DPI_SCALE = "${toString config.user.ui.gtk.scale}"
            '';
          };
        };
    };
  };
}
