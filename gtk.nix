{
  config,
  pkgs,
  lib,
  profile,
  ...
}: {
  gtk = {
    enable = true;
    font = {
      name = "${profile.mainFont.name}";
      size = 12;
    };
    gtk3.extraConfig = {
      gtk-xft-antialias = 1;
      gtk-xft-hinting = 1;
      gtk-xft-hintstyle = "hintslight";
      gtk-xft-rgba = "rgb";
      gtk-xft-dpi = toString profile.dpi;
      gtk-application-prefer-dark-theme = 1;
    };
    gtk3.extraCss = ''
      * {
        font-family: "${profile.mainFont.name}";
        color: #ffffff;
        background: transparent;
        outline-width: 0;
        outline-offset: 0;
      }

      *:hover {
        background: rgba(100, 149, 237, 0.1);
      }

      *:selected {
        background: rgba(100, 149, 237, 0.5);
      }

      button {
        border-radius: 2pt;
        min-height: 12pt;
        padding: 0.75pt 3pt;
      }

      menu {
        background: #333333;
      }
    '';
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
}
