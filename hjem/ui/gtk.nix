###############################################################################
# GTK Module for Hjem
# Configures GTK theming and appearance settings using Hjem file management
# - Generates GTK3/GTK4 settings.ini files using toINI
# - Creates custom CSS for enhanced theming
# - Manages GTK bookmarks from shared configuration
# - Supports DPI and scaling configuration
###############################################################################
{
  config,
  lib,
  pkgs,
  hostHome,
  ...
}: let
  cfg = config.cfg.hjome.ui.gtk;

  #############################################################
  # Extract common variables from the hostHome for reusability
  #############################################################
  mainFontName = (builtins.elemAt hostHome.cfg.appearance.fonts.main 0).name;
  inherit (hostHome.cfg.appearance) baseFontSize;
  dpiStr = toString hostHome.cfg.appearance.dpi;

  # Get user bookmarks from host configuration
  inherit (hostHome.cfg.user) bookmarks;

  # Get the scaling factor from config (defaults to 1.0)
  scaleFactor = cfg.scale;

  #############################################################
  # DConf settings configuration
  #############################################################
  dconfSettings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      text-scaling-factor = scaleFactor;
      scaling-factor = scaleFactor;
    };
  };

  # Generate INI content for dconf (similar to Home Manager approach)
  dconfIni = lib.generators.toINI {} dconfSettings;

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
      gtk-cursor-theme-size = toString (24 * scaleFactor);
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
      gtk-cursor-theme-size = toString (24 * scaleFactor);
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
  options.cfg.hjome.ui.gtk = {
    enable = lib.mkEnableOption "GTK theming and configuration using Hjem";

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
    # Package Installation
    ######################################################################
    packages = with pkgs; [
      gtk3
      gtk4
    ];

    ######################################################################
    # Hjem File Management
    ######################################################################
    files = {
      # GTK-3.0 configuration files
      ".config/gtk-3.0/settings.ini".text = lib.generators.toINI {} gtk3Settings;
      ".config/gtk-3.0/gtk.css".text = gtkCss;
      ".config/gtk-3.0/bookmarks".text = bookmarksContent;

      # GTK-4.0 configuration files
      ".config/gtk-4.0/settings.ini".text = lib.generators.toINI {} gtk4Settings;
    };

    ######################################################################
    # Environment Variables (via .zshenv for scaling)
    ######################################################################
    files.".zshenv".text = lib.mkAfter ''
      # GTK cursor size scales proportionally with the scaling factor
      export XCURSOR_SIZE="${toString (24 * scaleFactor)}"
    '';

    ######################################################################
    # DConf Settings (proper INI generation + dconf load like Home Manager)
    ######################################################################
    
    # Generate the dconf settings INI file
    files.".config/dconf-settings.ini".text = dconfIni;
    
    # Create loader script that uses dconf load (like Home Manager)
    files.".local/bin/load-dconf-settings".text = ''
      #!/usr/bin/env bash
      # Load dconf settings from INI file (similar to Home Manager activation)
      
      # Check if dconf is available
      if ! command -v dconf &> /dev/null; then
        exit 0
      fi
      
      # Check if settings file exists
      SETTINGS_FILE="$HOME/.config/dconf-settings.ini"
      if [[ ! -f "$SETTINGS_FILE" ]]; then
        exit 0
      fi
      
      # Load settings using dconf load (same as Home Manager)
      if [[ -v DBUS_SESSION_BUS_ADDRESS ]]; then
        dconf load / < "$SETTINGS_FILE"
      else
        ${pkgs.dbus}/bin/dbus-run-session --dbus-daemon=${pkgs.dbus}/bin/dbus-daemon -- dconf load / < "$SETTINGS_FILE"
      fi
    '';
    
    # Make the loader script executable
    files.".local/bin/load-dconf-settings".executable = true;
    
    # Auto-load dconf settings on shell startup
    files.".zshrc".text = lib.mkAfter ''
      
      # Load dconf settings if they exist
      if [[ -x "$HOME/.local/bin/load-dconf-settings" ]]; then
        "$HOME/.local/bin/load-dconf-settings" 2>/dev/null
      fi
    '';
  };
}
