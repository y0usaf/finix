###############################################################################
# Whisper Overlay Module
# Provides real-time speech-to-text capabilities
# - Configures the whisper-overlay service
# - Enables real-time transcription with GPU acceleration
###############################################################################
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.whisper-overlay.homeManagerModules.default
  ];

  # Enable the user service
  services.realtime-stt-server = {
    enable = true;
    # Auto-start with graphical session
    autoStart = true;
  };

  # Add the whisper-overlay package
  home.packages = [pkgs.whisper-overlay];
}
