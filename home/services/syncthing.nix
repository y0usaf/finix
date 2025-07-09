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
      # Syncthing User Service
      ###########################################################################
      systemd.services.syncthing = {
        description = "Syncthing - Open Source Continuous File Synchronization";
        after = ["graphical-session.target"];
        wantedBy = ["default.target"];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.syncthing}/bin/syncthing -no-browser -no-restart -logflags=0";
          Restart = "on-failure";
          RestartSec = "1";
          SuccessExitStatus = "3 4";
          RestartForceExitStatus = "3 4";
          User = "y0usaf";
          Group = "users";
          Environment = [
            "STNORESTART=1"
            "STNOUPGRADE=1"
          ];
        };
      };
    };
  };
}
