###############################################################################
# Audio Service Configuration
# Audio service via Pipewire:
# - Pipewire audio server
# - ALSA and PulseAudio compatibility
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
    # Audio via Pipewire
    # Modern audio server with compatibility layers
    ###########################################################################
    services.pipewire = {
      enable = true;
      alsa = {
        enable = true; # Enable ALSA compatibility layer.
        support32Bit = true; # Support for 32-bit audio applications.
      };
      pulse.enable = true; # Enable PulseAudio emulation for compatibility.
    };
  };
}
