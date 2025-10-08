{
  config,
  lib,
  ...
}: let
  cfg = config.home.ui.gtk;
  mainFontName = (builtins.elemAt config.home.core.appearance.fonts.main 0).name;
  inherit (config.home.core.appearance) baseFontSize;
  dpiStr = toString config.home.core.appearance.dpi;
  inherit (config.home.core.user) bookmarks;
  scaleFactor = cfg.scale;

  styles = import ./css.nix {inherit config lib;};

  gtk3Settings = {
    Settings = {
      gtk-application-prefer-dark-theme = 1;
      gtk-cursor-theme-name = "DeepinDarkV20-x11";
      gtk-cursor-theme-size = toString (builtins.floor (24 * scaleFactor));
      gtk-font-name = "${mainFontName} ${toString baseFontSize}";
      gtk-xft-antialias = 1;
      gtk-xft-dpi = dpiStr;
      gtk-xft-hinting = 1;
      gtk-xft-hintstyle = "hintslight";
      gtk-xft-rgba = "rgb";
    };
  };

  gtk4Settings = {
    Settings = {
      gtk-application-prefer-dark-theme = 1;
      gtk-cursor-theme-name = "DeepinDarkV20-x11";
      gtk-cursor-theme-size = toString (builtins.floor (24 * scaleFactor));
      gtk-font-name = "${mainFontName} ${toString baseFontSize}";
    };
  };

  bookmarksContent = lib.concatStringsSep "\n" bookmarks;
in {
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      gtk3
      gtk4
    ];
    usr = {
      files = {
        ".config/gtk-3.0/settings.ini" = {
          clobber = true;
          generator = lib.generators.toINI {};
          value = gtk3Settings;
        };
        ".config/gtk-3.0/gtk.css" = {
          clobber = true;
          text = styles.gtkCss;
        };
        ".config/gtk-3.0/bookmarks" = {
          clobber = true;
          text = bookmarksContent;
        };
        ".config/gtk-4.0/settings.ini" = {
          clobber = true;
          generator = lib.generators.toINI {};
          value = gtk4Settings;
        };
        ".zshenv" = {
          clobber = true;
          text = lib.mkAfter ''
            export XCURSOR_SIZE="${builtins.replaceStrings [".0"] [""] (toString (builtins.floor (24 * scaleFactor)))}"
          '';
        };
      };
    };
  };
}
