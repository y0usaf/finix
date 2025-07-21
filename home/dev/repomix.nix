###############################################################################
# Repomix Development Module (Maid Version)
# Tool to pack repository contents to single file for AI consumption
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.dev.repomix;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.home.dev.repomix = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable repomix tool for AI-friendly repository packing";
    };
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Maid Configuration
    ###########################################################################
    users.users.y0usaf.maid = {
      packages = with pkgs; [
        repomix
      ];
    };
  };
}
