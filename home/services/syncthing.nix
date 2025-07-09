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
      # Syncthing Configuration Directory
      ###########################################################################
      file.xdg_config."syncthing/.keep".text = '''';
    };

    ###########################################################################
    # Enable system syncthing user service
    ###########################################################################
    systemd.user.services.syncthing = {
      enable = true;
      wantedBy = ["default.target"];
      after = ["network.target"];
      serviceConfig = {
        ExecStart = "${pkgs.syncthing}/bin/syncthing serve --no-browser --no-restart --logflags=0";
        Restart = "on-failure";
        RestartSec = "5s";
        # User/Group handled by systemd --user
        WorkingDirectory = "/home/y0usaf";
        StateDirectory = "syncthing";
        StateDirectoryMode = "0700";
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        ReadWritePaths = ["/home/y0usaf"];
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        LockPersonality = true;
        RestrictAddressFamilies = ["AF_UNIX" "AF_INET" "AF_INET6"];
        SystemCallFilter = "@system-service";
        SystemCallErrorNumber = "EPERM";
      };
    };
  };
}
