###############################################################################
# Cursor Configuration
# Configures cursor themes for X11 and Wayland/Hyprland
# - Custom DeepinDarkV20 cursor themes
# - Separate X11 and Hyprland cursor packages
# - System-wide cursor configuration
###############################################################################
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  cfg = config.cfg.home.ui.cursor;
  hyprThemeName = "DeepinDarkV20-hypr";
  x11ThemeName = "DeepinDarkV20-x11";

  # Get the packages directly from flake outputs
  hyprcursorPackage = inputs.deepin-dark-hyprcursor.packages.${pkgs.system}.default;
  xcursorPackage = inputs.deepin-dark-xcursor.packages.${pkgs.system}.default;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.home.ui.cursor = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable cursor theme configuration";
    };
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Package Installation
    ###########################################################################
    users.users.y0usaf.maid.packages = with pkgs; [
      hyprcursorPackage
      xcursorPackage
    ];

    ###########################################################################
    # Home Manager Configuration
    ###########################################################################
    home-manager.users.y0usaf = {
      home.pointerCursor = {
        name = x11ThemeName;
        package = xcursorPackage;
        size = config.cfg.home.core.appearance.cursorSize;

        gtk.enable = true;
        x11.enable = true;
      };

      # Environment variables for proper Hyprland cursor support
      home.sessionVariables = {
        HYPRCURSOR_THEME = lib.mkForce hyprThemeName;
        HYPRCURSOR_SIZE = lib.mkForce (toString config.cfg.home.core.appearance.cursorSize);
        XCURSOR_THEME = lib.mkForce x11ThemeName;
        XCURSOR_SIZE = lib.mkForce (toString config.cfg.home.core.appearance.cursorSize);
      };

      # Separate GTK cursor configuration for X11 compatibility
      gtk.cursorTheme = {
        name = x11ThemeName;
        package = xcursorPackage;
        size = config.cfg.home.core.appearance.cursorSize;
      };
    };
  };
}