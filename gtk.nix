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
      size = 11;
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
        font-family: ${profile.mainFont.name};
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
        border-radius: 4px;
        min-height: 24px;
        padding: 2px 6px;
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
