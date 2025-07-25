{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.services.polkitGnome;
in {
  options.home.services.polkitGnome = {
    enable = lib.mkEnableOption "polkit GNOME authentication agent";
  };
  config = lib.mkIf cfg.enable {
    users.users.${config.user.name}.maid = {
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
