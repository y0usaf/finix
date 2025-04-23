###############################################################################
# NH Configuration Module
# - Configures the NH flake helper tool
# - Sets up automatic cleaning
###############################################################################
{
  config,
  pkgs,
  lib,
  hostSystem,
  hostHome,
  ...
}: {
  programs.nh = {
    enable = true;
    flake = hostHome.cfg.directories.flake.path;
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep-since 7d";
    };
  };
}
