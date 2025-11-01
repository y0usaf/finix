{
  config,
  lib,
  pkgs,
  ...
}: let
  scaleFactor = config.user.ui.gtk.scale;

  gtk3Settings = {
    Settings = {
      gtk-application-prefer-dark-theme = 1;
      gtk-cursor-theme-name = "DeepinDarkV20-x11";
      gtk-cursor-theme-size = toString (builtins.floor (24 * scaleFactor));
      gtk-font-name = "${config.user.ui.fonts.mainFontName} ${toString config.user.appearance.baseFontSize}";
      gtk-xft-antialias = 1;
      gtk-xft-dpi = toString config.user.appearance.dpi;
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
      gtk-font-name = "${config.user.ui.fonts.mainFontName} ${toString config.user.appearance.baseFontSize}";
    };
  };
in {
  config = lib.mkIf config.user.ui.gtk.enable {
    environment.systemPackages = [
      pkgs.gtk3
      pkgs.gtk4
    ];
    usr = {
      files =
        {
          ".config/gtk-3.0/settings.ini" = {
            clobber = true;
            generator = lib.generators.toINI {};
            value = gtk3Settings;
          };
          ".config/gtk-3.0/gtk.css" = {
            clobber = true;
            text = (import ./css.nix {inherit config lib;}).gtkCss;
          };
          ".config/gtk-3.0/bookmarks" = {
            clobber = true;
            text = lib.concatStringsSep "\n" config.user.paths.bookmarks;
          };
          ".config/gtk-4.0/settings.ini" = {
            clobber = true;
            generator = lib.generators.toINI {};
            value = gtk4Settings;
          };
        }
        // lib.optionalAttrs config.user.shell.zsh.enable {
          ".config/zsh/.zshenv" = {
            clobber = true;
            text = lib.mkAfter ''
              export XCURSOR_SIZE="${builtins.replaceStrings [".0"] [""] (toString (builtins.floor (24 * scaleFactor)))}"
              export GDK_DPI_SCALE="${toString scaleFactor}"
            '';
          };
        };
    };
  };
}
