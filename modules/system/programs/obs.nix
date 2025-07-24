{config, ...}: {
  boot = {
    kernelModules = ["v4l2loopback"];
    extraModulePackages = with config.boot.kernelPackages; [v4l2loopback];
    extraModprobeConfig = ''
      options v4l2loopback exclusive_caps=1
    '';
  };
  security.polkit.enable = true;
}
