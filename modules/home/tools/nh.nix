###############################################################################
# NH Configuration Module
# - Configures the NH flake helper tool
# - Sets up automatic cleaning
###############################################################################
{
  config,
  pkgs,
  lib,
  host,
  ...
}: {
  programs.nh = {
    enable = true;
    flake = host.cfg.directories.flake.path;
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep-since 7d";
    };
  };
}
