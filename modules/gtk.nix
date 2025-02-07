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

      bookmarks = profile.bookmarks;

      # ---------------------------------------------------------------
      # Updated Custom CSS for GTK3 Applications
      # ---------------------------------------------------------------
      extraCss = ''
        /* Global reset and minimal styling */
        * {
          font-family: "${mainFontName}";
          color: ${whiteColor};
          background-color: ${transparentColor};
          /* Remove default outlines but add transitions */
          outline: none;
          text-shadow: ${repeatedShadow};
          transition: background-color 0.2s ease-in-out, color 0.2s ease-in-out;
        }

        /* Focus state for accessibility (subtle focus ring) */
        *:focus {
          box-shadow: 0 0 0 2px ${hoverBg};
        }

        /* Hover state for all elements */
        *:hover {
          background-color: ${hoverBg};
        }

        /* Selected state for all elements */
        *:selected {
          background-color: ${selectedBg};
        }

        /* Button styling with hover/active transitions */
        button {
          border: none;
          border-radius: 0.15rem;
          min-height: 1rem;
          padding: 0.05rem 0.25rem;
          background-color: ${transparentColor};
          transition: background-color 0.2s ease-in-out;
        }

        button:hover {
          background-color: ${hoverBg};
        }

        button:active {
          background-color: ${selectedBg};
        }

        /* Menu, menubar, and menuitem styling */
        menu, menubar, menuitem {
          background-color: ${menuBackground};
        }

        /* Text selection styling to keep the look consistent */
        ::selection {
          background-color: ${hoverBg};
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
