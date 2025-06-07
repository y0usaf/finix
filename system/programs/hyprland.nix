###############################################################################
# Hyprland Window Manager Configuration
# Hyprland window manager setup:
# - Hyprland package and configuration
# - XWayland support
###############################################################################
{
  lib,
  pkgs,
  hostHjem,
  inputs,
  config,
  ...
}: {
  config = {
    ###########################################################################
    # Hyprland Window Manager
    # Tiling window manager for Wayland
    ###########################################################################
    programs.hyprland = lib.mkIf (hostHjem.cfg.hjome.ui.wayland.enable or true) {
      enable = true;
      xwayland.enable = true; # Enable XWayland to support legacy X11 apps.
      # Use the Hyprland package corresponding to the current system.
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    };
  };
}
