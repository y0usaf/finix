###############################################################################
# Polkit GNOME Authentication Agent Service
# Provides graphical authentication prompts for privileged operations
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.cfg.services.polkitGnome;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.services.polkitGnome = {
    enable = lib.mkEnableOption "polkit GNOME authentication agent";
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
