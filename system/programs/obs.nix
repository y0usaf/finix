{
  config,
  ...
}: {
  boot = {
    kernelModules = ["v4l2loopback"];
    extraModulePackages = with config.boot.kernelPackages; [v4l2loopback];
    extraModprobeConfig = ''
      # exclusive_caps: Chromium, Electron, etc. will only show device when actually streaming
      options v4l2loopback exclusive_caps=1
    '';
  };

  # UDEV rules for video devices have been moved to the system/modules/hardware/video.nix file

  # Polkit is required for some desktop/portal integrations
  security.polkit.enable = true;
}
