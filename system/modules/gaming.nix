###############################################################################
# Gaming System Module
# System-level configuration for gaming
# - Steam hardware support
# - Controller-related udev rules
###############################################################################
{
  config,
  lib,
  pkgs,
  hostSystem,
  hostHome,
  ...
}: let
  # Get the gaming configuration from the home config
  homeCfg = hostHome.cfg or {};
  gamingCfg = homeCfg.programs.gaming or {};
  controllerCfg = gamingCfg.controllers or {};
in {
  config = {
    ###########################################################################
    # Steam Hardware Support
    # Enable steam-hardware support if controllers are enabled in home config
    ###########################################################################
    hardware.steam-hardware.enable = lib.mkIf (controllerCfg.enable or false) true;
  };
}