###############################################################################
# NH Configuration Module
# - Configures the NH flake helper tool
# - Sets up automatic cleaning
###############################################################################
{
  config,
  pkgs,
  lib,
  profile,
  ...
}: {
  programs.nh = {
    enable = true;
    flake = profile.modules.directories.flake.path;
    clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep-since 7d";
    };
  };
}
