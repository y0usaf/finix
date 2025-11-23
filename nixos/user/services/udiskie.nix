{
  config,
  pkgs,
  lib,
  ...
}: {
  options.user.services.udiskie = {
    enable = lib.mkEnableOption "udiskie USB auto-mounting";
  };
  config = lib.mkIf config.user.services.udiskie.enable {
    systemd.user.services.udiskie = {
      description = "udiskie USB auto-mounting";
      wantedBy = ["graphical-session.target"];
      after = ["graphical-session.target"];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.udiskie}/bin/udiskie --automount --notify --smart-tray";
        Restart = "on-failure";
        RestartSec = 1;
      };
    };
  };
}
