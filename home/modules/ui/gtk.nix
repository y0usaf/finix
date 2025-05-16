###############################################################################
# GTK Module
# Configures GTK theming and appearance settings
# - Customizes GTK3/GTK4 appearance with consistent styling
# - Applies font configuration from host
# - Adds text shadow effects for better visibility
# - Sets DConf settings for GNOME desktop interface
###############################################################################
{
  config,
  pkgs,
  lib,
  hostSystem,
  hostHome,
  ...
}: let
  cfg = config.cfg.ui.gtk;

  #############################################################
  # Extract common variables from the hostHome for reusability
  #############################################################
  mainFontName = builtins.elemAt (builtins.elemAt hostHome.cfg.appearance.fonts.main 0) 1;
  baseFontSize = hostHome.cfg.appearance.baseFontSize;
  dpiStr = toString hostHome.cfg.appearance.dpi;

  # Get the scaling factor from config
  scaleFactor = cfg.fractional-scaling.factor;
  # Get fractional scaling enable status from config
  useFractionalScaling = cfg.fractional-scaling.enable;
  # Integer scale factor (used when not using true fractional scaling)
  intScaleFactor =
    if scaleFactor >= 2
    then 2
    else 1;

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
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.ui.gtk = {
    enable = lib.mkEnableOption "GTK theming and configuration";

    fractional-scaling = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable fractional scaling for GTK applications";
      };

      factor = lib.mkOption {
        type = lib.types.float;
        default = 2.0;
        description = "Scaling factor to use (e.g., 1.25, 1.5, 1.75, 2.0)";
        example = 1.5;
      };
    };
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
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

        bookmarks = hostHome.cfg.user.bookmarks;

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
      settings = lib.mkMerge [
        {
          "org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
            scaling-factor = lib.hm.gvariant.mkUint32 (
              if cfg.fractional-scaling.enable
              then 1
              else 2
            );
          };
        }
        (lib.mkIf (!useFractionalScaling) {
          "org/gnome/desktop/interface" = {
            # Set text scaling factor for fractional scaling
            text-scaling-factor = scaleFactor;
          };
        })
        (lib.mkIf useFractionalScaling {
          "org/gnome/mutter" = {
            # Enable experimental features for fractional scaling
            experimental-features = ["scale-monitor-framebuffer"];
          };
        })
      ];
    };

    ######################################################################
    # Set user-specific environment variables for GTK scaling
    ######################################################################
    home.sessionVariables = lib.mkMerge [
      (lib.mkIf (!useFractionalScaling) {
        # For integer+fractional scaling
        GDK_SCALE = intScaleFactor;
        GDK_DPI_SCALE =
          if intScaleFactor > 1
          then scaleFactor / intScaleFactor
          else scaleFactor;
      })
      (lib.mkIf useFractionalScaling {
        # For true fractional scaling in Wayland
        GDK_DPI_SCALE_WAYLAND = scaleFactor;
      })
      {
        # Cursor size scales in both cases
        XCURSOR_SIZE = toString (24
          * (
            if useFractionalScaling
            then scaleFactor
            else intScaleFactor
          ));
      }
    ];
  };
}
