###############################################################################
# Whisper Overlay Module Wrapper
# Imports the fixed whisper-overlay module and passes necessary arguments
###############################################################################
{ config, pkgs, lib, whisper-overlay, ... }:

{
  # Only import the fixed module if the feature is enabled
  imports = lib.mkIf config.modules.programs.whisper-overlay.enable [
    # Import the fixed module, passing the whisper-overlay flake directly
    (import ./fixed/whisper-overlay.nix {
      inherit config pkgs lib whisper-overlay;
    })
  ];
}