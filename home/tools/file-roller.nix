###############################################################################
# File Roller (Archive Manager) Module (Maid Version)
# Provides the file-roller GUI archive manager
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.cfg.home.tools.file-roller;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.home.tools.file-roller = {
    enable = lib.mkEnableOption "file-roller (archive manager)";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    users.users.y0usaf.maid.packages = with pkgs; [
      file-roller
    ];
  };
}
