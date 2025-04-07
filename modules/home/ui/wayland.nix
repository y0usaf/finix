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
  profile,
  ...
}: let
  cfg = config.cfg.ui.wayland;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.ui.wayland = {
    enable = lib.mkEnableOption "Wayland configuration";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Environment Variables
    ###########################################################################
    programs.zsh = {
      envExtra = ''
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
    };

    ###########################################################################
    # Packages
    ###########################################################################
    home.packages = with pkgs; [
      grim # Screenshot utility for Wayland
      slurp # Screen region selector tool
      wl-clipboard # Clipboard utility for Wayland
      hyprpicker # Color picker for Hyprland
    ];
  };
}
