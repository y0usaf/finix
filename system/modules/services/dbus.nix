###############################################################################
# D-Bus Service Configuration
# Inter-process communication system:
# - D-Bus service configuration
# - Package dependencies
###############################################################################
{
  config,
  lib,
  pkgs,
  hostSystem,
  hostHome,
  ...
}: {
  config = {
    ###########################################################################
    # D-Bus Configuration
    # Inter-process communication system
    ###########################################################################
    services.dbus = {
      enable = true;
      packages = [
        pkgs.dconf # A backend for system configuration.
        pkgs.gcr # GNOME crypto resource management library.
      ];
    };
  };
}
