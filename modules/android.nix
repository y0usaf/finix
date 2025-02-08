{
  config,
  pkgs,
  lib,
  profile,
  ...
}: {
  home.packages = with pkgs; [
    waydroid
    android-tools
    scrcpy
  ];

  systemd.user.services = {
    waydroid-container = {
      Unit = {
        Description = "Waydroid Container";
        After = ["graphical-session.target"];
        PartOf = ["graphical-session.target"];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.waydroid}/bin/waydroid session start";
        ExecStop = "${pkgs.waydroid}/bin/waydroid session stop";
        Restart = "on-failure";
      };
    };
  };
}
