#===============================================================================
#
#                     Environment Variables Configuration
#
# Description:
#     System-wide environment variable configuration file. Manages:
#     - System environment variables
#     - Home Manager environment variables
#     - Hyprland-specific variables
#     - Path configurations
#
# Author: y0usaf
# Last Modified: 2025
#
#===============================================================================
{
  config,
  pkgs,
  lib,
  globals,
  ...
}: {
  #-----------------------------------------------------------------------------
  # System Environment Variables (configuration.nix)
  #-----------------------------------------------------------------------------
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
    QT_QPA_PLATFORM = "wayland";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
  };

  #-----------------------------------------------------------------------------
  # Home Manager Environment Variables
  #-----------------------------------------------------------------------------
  home-manager.users.${globals.username} = {
    home.sessionVariables = {
      # Core Path and Editor Settings
      EDITOR = globals.defaultEditor;
      BROWSER = globals.defaultBrowser;
    };

    #---------------------------------------------------------------------------
    # Hyprland Environment Variables
    #---------------------------------------------------------------------------
    wayland.windowManager.hyprland.settings = {
      env = [
        "LIBVA_DRIVER_NAME,nvidia"
        "GBM_BACKEND,nvidia-drm"
        "__GLX_VENDOR_LIBRARY_NAME,nvidia"
        "WLR_NO_HARDWARE_CURSORS,1"
      ];
    };
  };

  #-----------------------------------------------------------------------------
  # System PATH additions
  #-----------------------------------------------------------------------------
  environment.extraInit = ''
    export PATH="$HOME/.local/bin:$PATH"
    export PATH="/usr/lib/google-cloud-sdk/bin:$PATH"
  '';
}
