{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.services.polkitAgent;
in {
  options.home.services.polkitAgent = {
    enable = lib.mkEnableOption "polkit authentication agent";
  };
  config = lib.mkIf cfg.enable {
    users.users.y0usaf.maid = {
      packages = [pkgs.polkit_gnome];
      systemd.services.polkit-gnome-authentication-agent-1 = {
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
  };
}
