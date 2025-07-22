###############################################################################
# GTK Module for Maid
# Configures GTK theming and appearance settings using nix-maid file management
# - Generates GTK3/GTK4 settings.ini files using toINI
# - Creates custom CSS for enhanced theming
# - Manages GTK bookmarks from shared configuration
# - Supports DPI and scaling configuration
# - Uses nix-maid's native dconf and gsettings support
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.ui.gtk;

  #############################################################
  # Extract common variables from the appearance config
  #############################################################
  mainFontName = (builtins.elemAt config.home.core.appearance.fonts.main 0).name;
  inherit (config.home.core.appearance) baseFontSize;
  dpiStr = toString config.home.core.appearance.dpi;

  # Get user bookmarks from user config
  inherit (config.home.core.user) bookmarks;

  # Get the scaling factor from config (defaults to 1.0)
  scaleFactor = cfg.scale;

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
  repeatedShadow = lib.concatStringsSep ",\n" (lib.concatLists (lib.genList (_: shadowOffsets) 4));

  #############################################################
  # Define color constants for CSS styling
  #############################################################
  whiteColor = "#ffffff";
  transparentColor = "transparent";
  menuBackground = "#333333";
  hoverBg = "rgba(100, 149, 237, 0.1)";
  selectedBg = "rgba(100, 149, 237, 0.5)";

  #############################################################
  # GTK Settings Configuration for INI files
  #############################################################
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

  #############################################################
  # Custom CSS content
  #############################################################
  gtkCss = ''
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

  #############################################################
  # Convert bookmarks list to GTK bookmarks file format
  #############################################################
  bookmarksContent = lib.concatStringsSep "\n" bookmarks;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.home.ui.gtk = {
    enable = lib.mkEnableOption "GTK theming and configuration using nix-maid";

    scale = lib.mkOption {
      type = lib.types.float;
      default = 1.0;
      description = "Scaling factor for GTK applications (e.g., 1.0, 1.25, 1.5, 2.0)";
      example = 1.5;
    };
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ######################################################################
    # Maid Configuration
    ######################################################################
    users.users.y0usaf.maid = {
      ######################################################################
      # Package Installation
      ######################################################################
      packages = with pkgs; [
        gtk3
        gtk4
      ];

      ######################################################################
      # File Management
      ######################################################################
      file = {
        xdg_config = {
          # GTK-3.0 configuration files
          "gtk-3.0/settings.ini".text = lib.generators.toINI {} gtk3Settings;
          "gtk-3.0/gtk.css".text = gtkCss;
          "gtk-3.0/bookmarks".text = bookmarksContent;

          # GTK-4.0 configuration files
          "gtk-4.0/settings.ini".text = lib.generators.toINI {} gtk4Settings;
        };

        ######################################################################
        # Environment Variables (via .zshenv for scaling)
        ######################################################################
        home.".zshenv".text = lib.mkAfter ''
          # GTK cursor size scales proportionally with the scaling factor
          export XCURSOR_SIZE="${builtins.replaceStrings [".0"] [""] (toString (builtins.floor (24 * scaleFactor)))}"
        '';
      };

      ######################################################################
      # Native nix-maid DConf and GSettings Support
      ######################################################################
      # Temporarily disabled - schemas not available
      # gsettings.settings = {
      #   org.gnome.desktop.interface = {
      #     color-scheme = "prefer-dark";
      #     text-scaling-factor = scaleFactor;
      #     scaling-factor = scaleFactor;
      #   };
      # };

      # Temporarily disabled - may be causing issues
      # dconf.settings = {
      #   "/org/gnome/desktop/interface/color-scheme" = "prefer-dark";
      #   "/org/gnome/desktop/interface/text-scaling-factor" = scaleFactor;
      #   "/org/gnome/desktop/interface/scaling-factor" = scaleFactor;
      # };
    };
  };
}
