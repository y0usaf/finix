# This module configures the core system settings.
{config, ...}: {
  config = {
    system.stateVersion = config.cfg.shared.stateVersion;
    time.timeZone = config.cfg.shared.timezone;
    networking.hostName = config.cfg.shared.hostname;
    nixpkgs.config.allowUnfree = true;
  };
}
