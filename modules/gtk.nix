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
      # Custom CSS for GTK3 applications
      # ---------------------------------------------------------------
      extraCss = ''
        /* Global baseline styles with smooth transitions */
        * {
          font-family: "${mainFontName}";
          color: ${whiteColor};
          background: ${transparentColor};
          transition: background-color 0.2s ease, color 0.2s ease;
        }
        
        /* Apply subtle text shadow only to key text elements */
        label, button, entry, textview {
          text-shadow: ${repeatedShadow};
        }
        
        /* Hover and active states for interactive elements */
        *:hover,
        *:active {
          background: ${hoverBg};
        }
        
        /* Clear, minimal focus indicator for accessibility */
        *:focus {
          outline: 1px solid ${hoverBg};
          outline-offset: 0;
        }
        
        /* Button styling with improved interactivity */
        button {
          border: none;
          border-radius: 0.15rem;
          min-height: 1rem;
          padding: 0.1rem 0.3rem;
          cursor: pointer;
          background: ${transparentColor};
        }
        button:hover {
          background: ${hoverBg};
        }
        button:active {
          background: ${selectedBg};
        }
        
        /* Menu styling for a subtle appearance */
        menu {
          background: ${menuBackground};
        }
        
        /* Styling for input elements for consistency */
        entry,
        textview,
        combobox,
        spinbutton {
          background: ${transparentColor};
          border: 1px solid transparent;
          padding: 0.2rem;
        }
        entry:focus,
        textview:focus,
        combobox:focus,
        spinbutton:focus {
          border-color: ${hoverBg};
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
