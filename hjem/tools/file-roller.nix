###############################################################################
# File Roller (Archive Manager) Module (Hjem Version)  
# Provides the file-roller GUI archive manager
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.cfg.hjome.tools.file-roller;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.hjome.tools.file-roller = {
    enable = lib.mkEnableOption "file-roller (archive manager)";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    packages = with pkgs; [
      file-roller
    ];
  };
}