###############################################################################
# Whisper Overlay Configuration
# - Provides real-time speech-to-text capabilities
# - Configures the Home Manager service for whisper-overlay
###############################################################################
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  # Enable the user service
  services.realtime-stt-server = {
    enable = true;
    # Start the service automatically with graphical session
    autoStart = true;
  };

  # Add the whisper-overlay package to user packages
  home.packages = [pkgs.whisper-overlay];
}
