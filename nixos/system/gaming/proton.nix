{
  config,
  lib,
  ...
}: {
  options.gaming.proton = {
    enable = lib.mkEnableOption "Proton-GE for gaming";
    ntsync = lib.mkEnableOption "ntsync kernel module support";
    nativeWayland = lib.mkEnableOption "Wayland native Proton support";
  };

  config = lib.mkIf config.gaming.proton.enable {
    boot.kernelModules = lib.mkIf config.gaming.proton.ntsync ["ntsync"];

    services.udev.extraRules = lib.mkIf config.gaming.proton.ntsync ''
      KERNEL=="ntsync", MODE="0644"
    '';

    environment.sessionVariables =
      {
        PROTON_USE_WOW64 = "1";
      }
      // lib.optionalAttrs config.gaming.proton.nativeWayland {
        PROTON_ENABLE_WAYLAND = "1";
        PROTON_NO_WM_DECORATION = "1";
      };
  };
}
