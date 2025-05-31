###############################################################################
# Video Devices Configuration Module
# Hardware configuration for video peripherals:
# - Camera and video device permissions
# - Capture device settings
###############################################################################
_: {
  config = {
    ###########################################################################
    # Video Device Rules
    # Configure permissions for video devices for OBS and other capture software
    ###########################################################################
    services.udev.extraRules = ''
      # Video device permissions for capture software
      KERNEL=="video[0-9]*", GROUP="video", MODE="0660"
    '';
  };
}
