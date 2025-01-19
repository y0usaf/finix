{
  config,
  pkgs,
  lib,
  globals,
  ...
}: {
  gtk = {
    enable = true;
    font = {
      name = "monospace";
      size = 11;
    };
    gtk3.extraConfig = {
      gtk-xft-antialias = 1;
      gtk-xft-hinting = 1;
      gtk-xft-hintstyle = "hintslight";
      gtk-xft-rgba = "rgb";
      gtk-xft-dpi = 96;
      gtk-application-prefer-dark-theme = 1;
    };
    gtk3.extraCss = ''
      @keyframes fadeIn {
        0% { opacity: 0; }
        to { opacity: 1; }
      }

      @define-color primary #fff;
      @define-color secondary transparent;
      @define-color hover-color rgba(100, 149, 237, .1);
      @define-color selected-color rgba(100, 149, 237, .5);

      * {
        font-family: monospace;
        color: @primary;
        background: @secondary;
        text-shadow: 2px 2px 2px rgba(0, 0, 0, 0.5);
      }

      :hover {
        background: @hover-color;
      }

      :selected {
        background: @selected-color;
      }

      button {
        border-radius: 4px;
        transition: all 0.3s ease;
      }

      input:focus,
      select:focus,
      textarea:focus {
        box-shadow: 0 0 5px #51cbee;
        border: 1px solid #51cbee;
      }

      menu {
        background: #333;
      }

      .fade-in {
        opacity: 0;
        animation: fadeIn ease 1s;
        animation-fill-mode: forwards;
      }
    '';
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  dconf.enable = true;

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
}
