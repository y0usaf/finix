###############################################################################
# Input Devices Configuration Module
# Hardware configuration for input peripherals:
# - Keyboard configurations including Vial
# - Controller support and permissions
###############################################################################
{
  lib,
  hostSystem,
  ...
}: {
  config = {
    ###########################################################################
    # Vial Keyboard Rules
    # Allow access to Vial-compatible keyboard devices for non-root users
    ###########################################################################
    services.udev.extraRules = lib.mkMerge [
      # Vial rules for non-root access
      ''
        KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users"
        KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", TAG+="uaccess"
      ''

      # DualSense controller rules (only if controllers are enabled by host)
      (lib.mkIf (hostSystem.services.controllers.enable or false) ''
        # Sony DualSense controller - standard mode
        KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0ce6", MODE="0660", TAG+="uaccess"

        # Sony DualSense controller - bluetooth mode
        KERNEL=="hidraw*", KERNELS=="*054C:0CE6*", MODE="0660", TAG+="uaccess"

        # Sony DualSense Edge controller
        KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0df2", MODE="0660", TAG+="uaccess"
      '')
    ];
  };
}
