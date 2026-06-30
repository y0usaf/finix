{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.ui.niri.enable {
    manzil.users."${config.user.name}".files.".config/niri/config.kdl".value = {
      debug = {
        dbus-interfaces-in-non-session-instances = {};
      };

      environment =
        {
          DISPLAY = ":0";
        }
        // (lib.optionalAttrs config.hardware.nvidia.enable {
          GBM_BACKEND = "nvidia-drm";
          __GLX_VENDOR_LIBRARY_NAME = "nvidia";
          __EGL_VENDOR_LIBRARY_FILENAMES = "/run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json";
          LIBVA_DRIVER_NAME = "nvidia";
        });
    };
  };
}
