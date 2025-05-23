# This module configures the core system settings.
{
  config,
  lib,
  pkgs,
  hostSystem,
  hostHome,
  ...
}: {
  config = {
    system.stateVersion = hostSystem.cfg.system.stateVersion;
    time.timeZone = hostSystem.cfg.system.timezone;
    networking.hostName = hostSystem.cfg.system.hostname;
    nixpkgs.config.allowUnfree = true;
  };
}
