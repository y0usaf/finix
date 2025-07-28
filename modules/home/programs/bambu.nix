{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.programs.bambu;
  bambuStudio = pkgs.bambu-studio.overrideAttrs (_oldAttrs: {
    version = "01.00.01.50";
    src = pkgs.fetchFromGitHub {
      owner = "bambulab";
      repo = "BambuStudio";
      rev = "v01.00.01.50";
      hash = "sha256-7mkrPl2CQSfc1lRjl1ilwxdYcK5iRU//QGKmdCicK30=";
    };
  });
  bambuStudioWrapper = pkgs.writeShellScriptBin "bambu-studio" ''
    MESA_PATH="${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json"
    NVIDIA_PATH="/run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json"
    if lspci | grep -i nvidia >/dev/null && [ -f "$NVIDIA_PATH" ]; then
      export WEBKIT_DISABLE_DMABUF_RENDERER=1
      export GALLIUM_DRIVER=zink
      export MESA_LOADER_DRIVER_OVERRIDE=zink
      export __GLX_VENDOR_LIBRARY_NAME=mesa
      export __EGL_VENDOR_LIBRARY_FILENAMES="$MESA_PATH"
      exec ${bambuStudio}/bin/bambu-studio "$@"
    else
      if [ ! -f "$MESA_PATH" ]; then
        echo "\n\033[1;31mFATAL: Mesa EGL vendor file is required for Bambu Studio to run.\033[0m"
        echo "Expected at: $MESA_PATH"
        echo "This package will not run without it. Please ensure mesa is available."
        exit 1
      fi
      export __EGL_VENDOR_LIBRARY_FILENAMES=$MESA_PATH
      export WEBKIT_FORCE_COMPOSITING_MODE=1
      export WEBKIT_DISABLE_COMPOSITING_MODE=1
      export WEBKIT_DISABLE_DMABUF_RENDERER=1
      exec ${bambuStudio}/bin/bambu-studio "$@"
    fi
  '';
in {
  options.home.programs.bambu = {
    enable = lib.mkEnableOption "Bambu Studio 3D printing slicer";
  };
  config = lib.mkIf cfg.enable {
    hjem.users.${config.user.name}.packages = [
      bambuStudioWrapper
      pkgs.mesa
    ];
  };
}
