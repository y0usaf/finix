###############################################################################
# Polkit Authentication Agent Service
# Provides polkit authentication for desktop applications
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.cfg.services.polkitAgent;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.services.polkitAgent = {
    enable = lib.mkEnableOption "polkit authentication agent";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # System Packages
    ###########################################################################
    environment.systemPackages = with pkgs; [
      polkit_gnome
    ];

    ###########################################################################
    # Systemd User Service
    ###########################################################################
    systemd.user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = ["graphical-session.target"];
      after = ["graphical-session.target"];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };
}
