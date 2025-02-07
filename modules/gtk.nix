{
  config,
  pkgs,
  lib,
  profile,
  ...
}: let
  #############################################################
  # Extract common variables from the profile for reusability
  #############################################################
  mainFontName = builtins.elemAt (builtins.elemAt profile.fonts.main 0) 1;
  baseFontSize = profile.baseFontSize;
  dpiStr = toString profile.dpi;

  #############################################################
  # Text shadow configuration
  #############################################################
  shadowSize = "0.05rem";
  shadowRadius = "0.05rem";
  shadowColor = "#000000";

  # Define the 8 shadow offsets as a list
  shadowOffsets = [
    "${shadowSize} 0 ${shadowRadius} ${shadowColor}"
    "-${shadowSize} 0 ${shadowRadius} ${shadowColor}"
    "0 ${shadowSize} ${shadowRadius} ${shadowColor}"
    "0 -${shadowSize} ${shadowRadius} ${shadowColor}"
    "${shadowSize} ${shadowSize} ${shadowRadius} ${shadowColor}"
    "-${shadowSize} ${shadowSize} ${shadowRadius} ${shadowColor}"
    "${shadowSize} -${shadowSize} ${shadowRadius} ${shadowColor}"
    "-${shadowSize} -${shadowSize} ${shadowRadius} ${shadowColor}"
  ];

  # Generate repeated shadow string (4 repetitions)
  repeatedShadow = lib.concatStringsSep ",\n" (lib.concatLists (lib.genList (i: shadowOffsets) 4));

  #############################################################
  # Define color constants for CSS styling
  #############################################################
  whiteColor = "#ffffff";
  transparentColor = "transparent";
  menuBackground = "#333333";
  hoverBg = "rgba(100, 149, 237, 0.1)";
  selectedBg = "rgba(100, 149, 237, 0.5)";
in {
  ######################################################################
  # GTK Global Configuration
  ######################################################################
  gtk = {
    enable = true;

    # ---------------------------------------------------------------
    # Overall font settings for GTK
    # ---------------------------------------------------------------
    font = {
      name = mainFontName;
      size = baseFontSize;
    };

    ##################################################################
    # GTK3 Specific Configuration
    ##################################################################
    gtk3 = {
      extraConfig = {
        gtk-xft-antialias = 1;
        gtk-xft-hinting = 1;
        gtk-xft-hintstyle = "hintslight";
        gtk-xft-rgba = "rgb";
        gtk-xft-dpi = dpiStr;
        gtk-application-prefer-dark-theme = 1;
      };

      bookmarks = [
        "file:///home/username/Downloads"
        "file:///home/username/Music"
        "file:///home/username/DCIM"
        "file:///home/username/nixos"
        "file:///home/username/.local/share/Steam"
     ];

      # ---------------------------------------------------------------
      # Custom CSS for GTK3 applications
      # ---------------------------------------------------------------
      extraCss = ''
        /* Global element styling */
        * {
          font-family: "${mainFontName}";
          color: ${whiteColor};
          background: ${transparentColor};
          outline-width: 0;
          outline-offset: 0;
          text-shadow: ${repeatedShadow};
        }

        /* Hover state for all elements */
        *:hover {
          background: ${hoverBg};
        }

        /* Selected state for all elements */
        *:selected {
          background: ${selectedBg};
        }

        /* Button styling */
        button {
          border-radius: 0.15rem;
          min-height: 1rem;
          padding: 0.05rem 0.25rem;
        }

        /* Menu background styling */
        menu {
          background: ${menuBackground};
        }
      '';
    };

    ##################################################################
    # GTK4 Specific Configuration
    ##################################################################
    gtk4 = {
      extraConfig = {
        gtk-application-prefer-dark-theme = 1;
      };
    };
  };

  ######################################################################
  # DConf Settings for the GNOME Desktop Interface
  ######################################################################
  dconf = {
    settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };
    };
  };
}
