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
        Requires = ["waydroid-container.service"];
      };
      Service = {
        Type = "simple";
        Environment = [
          "WAYDROID_EXTRA_ARGS=--gpu-mode host"
          "LIBGL_DRIVER_NAME=nvidia"
          "GBM_BACKEND=nvidia-drm"
          "__GLX_VENDOR_LIBRARY_NAME=nvidia"
        ];
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
        ExecStart = "${pkgs.waydroid}/bin/waydroid session start";
        ExecStop = "${pkgs.waydroid}/bin/waydroid session stop";
        Restart = "on-failure";
        RestartSec = "5s";
      };
      Install = {
        WantedBy = ["graphical-session.target"];
      };
    };
  };
}
