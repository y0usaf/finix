{pkgs, ...}: {
  # Window border effects for macOS
  environment.systemPackages = with pkgs; [
    jankyborders
  ];

  # Start jankyborders on boot
  launchd.daemons.jankyborders = {
    script = "${pkgs.jankyborders}/bin/borders";
    serviceConfig = {
      KeepAlive = true;
      RunAtLoad = true;
      StandardOutPath = "/var/log/jankyborders.log";
      StandardErrorPath = "/var/log/jankyborders.log";
    };
  };
}
