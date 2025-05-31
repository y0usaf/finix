###############################################################################
# Gaming Controllers Module
# Configuration for game controllers and peripherals
# - General controller support including DualSense (PS5)
# - Automatically enables system-level controller support
###############################################################################
{
  config,
  lib,
  pkgs,
  host,
  hostSystem,
  ...
}: let
  cfg = config.cfg.gaming.controllers;
in {
  options.cfg.gaming.controllers = {
    enable = lib.mkEnableOption "gaming controller support";
  };

  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Controller Packages
    ###########################################################################

    # General controller support including DualSense (PS5)
    home.packages = with pkgs; [
      dualsensectl # Command-line tool for DualSense controller
      # trigger-control  # Optional GUI tool for adaptive triggers (uncomment if needed)
    ];

    ###########################################################################
    # System Integration
    # The system module will automatically enable hardware.steam-hardware.enable
    # when this option is enabled.
    ###########################################################################
  };
}
