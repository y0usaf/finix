{
  config,
  lib,
  ...
}: let
  inherit (config.user) appearance ui;
  inherit (appearance) xcursorSize;
  inherit (ui) cursor;
in {
  config = lib.mkIf config.user.ui.sway.enable {
    programs.sway.extraSessionCommands = lib.mkAfter (''
        export XDG_CURRENT_DESKTOP=sway
        export XDG_SESSION_DESKTOP=sway
        export XDG_SESSION_TYPE=wayland
        export NIXOS_OZONE_WL=1
        export QT_QPA_PLATFORM=wayland
        export ELECTRON_OZONE_PLATFORM_HINT=wayland
        export GDK_BACKEND=wayland
        export SDL_VIDEODRIVER=wayland,x11
        export CLUTTER_BACKEND=wayland
        export GDK_DPI_SCALE=${toString config.user.ui.gtk.scale}
        export XCURSOR_THEME=${cursor.package.xcursorThemeName}
        export XCURSOR_SIZE=${toString xcursorSize}
      ''
      + lib.optionalString config.hardware.nvidia.enable ''
        export WLR_NO_HARDWARE_CURSORS=1
        export GBM_BACKEND=nvidia-drm
        export __GLX_VENDOR_LIBRARY_NAME=nvidia
        export __EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json
        export LIBVA_DRIVER_NAME=nvidia
      '');
  };
}
