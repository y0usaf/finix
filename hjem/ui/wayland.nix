###############################################################################
# Wayland Module
# Configures Wayland-specific settings and utilities
# - Sets Wayland environment variables
# - Installs Wayland-specific utilities
# - Provides consistent Wayland experience across applications
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.cfg.hjome.ui.wayland;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.hjome.ui.wayland = {
    enable = lib.mkEnableOption "Wayland configuration";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Environment Variables (via .zshenv for Wayland)
    ###########################################################################
    files.".zshenv".text = lib.mkAfter ''
      # Wayland environment variables
      export WLR_NO_HARDWARE_CURSORS=1
      export NIXOS_OZONE_WL=1
      export QT_QPA_PLATFORM=wayland
      export ELECTRON_OZONE_PLATFORM_HINT=wayland
      export XDG_SESSION_TYPE=wayland
      export GDK_BACKEND=wayland,x11
      export SDL_VIDEODRIVER=wayland
      export CLUTTER_BACKEND=wayland
    '';

    ###########################################################################
    # Packages
    ###########################################################################
    packages = with pkgs; [
      grim # Screenshot utility for Wayland
      slurp # Screen region selector tool
      wl-clipboard # Clipboard utility for Wayland
      hyprpicker # Color picker for Hyprland
    ];
  };
}
