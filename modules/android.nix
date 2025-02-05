{
  config,
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    # Android development and emulation tools
    waydroid
    android-tools # adb, fastboot, etc.
    scrcpy # Android screen mirroring
  ];

  # Waydroid systemd service
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
