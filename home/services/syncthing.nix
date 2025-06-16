###############################################################################
# Syncthing Configuration (Maid Version)
# Simple syncthing service enablement
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.services.syncthing;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.home.services.syncthing = {
    enable = lib.mkEnableOption "Syncthing service";
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
        syncthing
      ];

      ###########################################################################
      # Enable existing syncthing systemd service
      ###########################################################################
      systemd.services.syncthing = {
        enable = true;
        wantedBy = ["default.target"];
      };
    };
  };
}
