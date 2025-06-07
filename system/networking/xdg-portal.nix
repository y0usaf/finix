###############################################################################
# XDG Desktop Portal Configuration
# Desktop integration services for applications
###############################################################################
{
  lib,
  pkgs,
  hostHjem,
  ...
}: {
  config = {
    ###########################################################################
    # XDG Desktop Portal
    # Desktop integration services for applications
    ###########################################################################
    xdg.portal = lib.mkIf (hostHjem.cfg.hjome.ui.wayland.enable or true) {
      enable = true;
      xdgOpenUsePortal = true; # Route xdg-open calls through the portal for better integration.
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk # Add GTK-based portal support.
      ];
    };
  };
}
