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
  hostSystem,
  hostHome,
  ...
}: let
  cfg = config.cfg.ui.cursor;
  hyprThemeName = "DeepinDarkV20-hypr";
  x11ThemeName = "DeepinDarkV20-x11";
  
  # Get the packages directly from flake outputs
  hyprcursorPackage = inputs.deepin-dark-hyprcursor.packages.${pkgs.system}.default;
  xcursorPackage = inputs.deepin-dark-xcursor.packages.${pkgs.system}.default;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.ui.cursor = {
    enable = lib.mkEnableOption "cursor theme configuration";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    home.packages = [hyprcursorPackage xcursorPackage];

    ###########################################################################
    # Cursor Configuration
    ###########################################################################
    home.pointerCursor = {
      name = x11ThemeName;
      package = xcursorPackage;
      size = hostHome.cfg.appearance.cursorSize;

      gtk.enable = true;
      x11.enable = true;
      hyprcursor.enable = true;
    };

    gtk.cursorTheme = {
      name = x11ThemeName;
      package = xcursorPackage;
      size = hostHome.cfg.appearance.cursorSize;
    };
  };
}
