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
  profile,
  ...
}: let
  cfg = config.cfg.ui.cursor;
  baseTheme = "DeepinDarkV20";

  hyprcursorPackage = pkgs.stdenv.mkDerivation {
    pname = "deepin-dark-v20-hyprcursor";
    version = "1.0";
    src = inputs.deepin-dark-hyprcursor;

    dontFixTimestamps = true;

    installPhase = ''
      # Create theme directory for Hyprland cursors
      mkdir -p $out/share/icons/${baseTheme}-hypr

      # Install Hyprland cursors
      cp -r $src/hyprcursors $out/share/icons/${baseTheme}-hypr/
      cp $src/manifest.hl $out/share/icons/${baseTheme}-hypr/
    '';
  };

  xcursorPackage = pkgs.stdenv.mkDerivation {
    pname = "deepin-dark-v20-xcursor";
    version = "1.0";
    src = inputs.deepin-dark-xcursor;

    installPhase = ''
      # Create theme directory for X11 cursors
      mkdir -p $out/share/icons/${baseTheme}-x11

      # Install X11 cursors with all symlinks
      cp -r $src/cursors $out/share/icons/${baseTheme}-x11/
      cp $src/index.theme $out/share/icons/${baseTheme}-x11/
    '';
  };
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
      name = "${baseTheme}-x11";
      package = xcursorPackage;
      size = profile.cfg.appearance.cursorSize;

      gtk.enable = true;
      x11.enable = true;
      hyprcursor.enable = true;
    };

    gtk.cursorTheme = {
      name = "${baseTheme}-x11";
      package = xcursorPackage;
      size = profile.cfg.appearance.cursorSize;
    };
  };
}
