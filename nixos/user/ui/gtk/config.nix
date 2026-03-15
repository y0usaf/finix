{
  config,
  lib,
  pkgs,
  ...
}: {
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
            text = (import ./css.nix {inherit config lib;}).gtkCss;
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
        // lib.optionalAttrs config.user.shell.zsh.enable {
          ".config/zsh/.zshenv" = {
            clobber = true;
            text = lib.mkAfter ''
              export XCURSOR_SIZE="${builtins.replaceStrings [".0"] [""] (toString (builtins.floor (24 * config.user.ui.gtk.scale)))}"
              export GDK_DPI_SCALE="${toString config.user.ui.gtk.scale}"
            '';
          };
        }
        // lib.optionalAttrs config.user.shell.nushell.enable {
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
