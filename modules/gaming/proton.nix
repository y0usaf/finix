{
  config,
  lib,
  ...
}: {
  options.user.gaming.proton = {
    enable = lib.mkEnableOption "Proton-GE for gaming";
    nativeWayland = lib.mkEnableOption "Wayland native Proton support";
    ntsync = lib.mkEnableOption "ntsync kernel module support";
  };

  config = lib.mkIf config.user.gaming.proton.enable {
    environment.variables =
      {
        PROTON_ENABLE_NGX_UPDATER = "1";
        DXVK_NVAPI_DRS_SETTINGS = "NGX_DLSS_SR_OVERRIDE=on,NGX_DLSS_RR_OVERRIDE=on,NGX_DLSS_FG_OVERRIDE=on,NGX_DLSS_SR_OVERRIDE_RENDER_PRESET_SELECTION=render_preset_latest,NGX_DLSS_RR_OVERRIDE_RENDER_PRESET_SELECTION=render_preset_latest";
      }
      // lib.optionalAttrs config.user.gaming.proton.nativeWayland {
        PROTON_ENABLE_WAYLAND = "1";
        PROTON_NO_WM_DECORATION = "1";
      };
  };
}
