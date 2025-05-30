###############################################################################
# Host Configuration Loader
# Automatically loads and merges host-specific configurations
###############################################################################
{
  lib,
  pkgs,
  hostSystem,
  ...
}: {
  # Import all system modules
  imports = [
    ../system/modules
  ];

  # Apply the configuration from the unified host config
  networking.hostName = hostSystem.cfg.system.hostname;
  time.timeZone = hostSystem.cfg.system.timezone;
  system.stateVersion = hostSystem.cfg.system.stateVersion;
  
  # Apply users configuration  
  inherit (hostSystem) users;
  
  # Hardware configuration
  hardware = {
    bluetooth.enable = hostSystem.cfg.hardware.bluetooth.enable or false;
  };
}