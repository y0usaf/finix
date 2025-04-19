{
  config,
  lib,
  pkgs,
  host,
  ...
}: {
  options.cfg.programs.bambu.enable = lib.mkEnableOption "Bambu Studio";

  config = lib.mkIf config.cfg.programs.bambu.enable (
    let
      _ =
        lib.assertMsg (builtins.pathExists "${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json")
        "FATAL: Mesa EGL vendor file is required for Bambu Studio to build. Expected at: ${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json\nThis package will not build without it. Please ensure mesa is available.";
      bambuStudio = pkgs.bambu-studio.overrideAttrs (oldAttrs: {
        version = "01.00.01.50";
        src = pkgs.fetchFromGitHub {
          owner = "bambulab";
          repo = "BambuStudio";
          rev = "v01.00.01.50";
          hash = "sha256-7mkrPl2CQSfc1lRjl1ilwxdYcK5iRU//QGKmdCicK30=";
        };
      });
      bambuStudioWrapper = pkgs.writeShellScriptBin "bambu-studio" ''
        # Use the mesa package path for the EGL vendor file
        MESA_PATH="${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json"
        NVIDIA_PATH="/run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json"

        # Detect if NVIDIA is in use
        if lspci | grep -i nvidia >/dev/null && [ -f "$NVIDIA_PATH" ]; then
          # NVIDIA detected, set special environment for zink/mesa
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
    in
      lib.mkMerge [
        {
          home.packages = [bambuStudioWrapper];
          home.file.".local/share/applications/bambu-studio.desktop".text = ''
            [Desktop Entry]
            Name=Bambu Studio
            Comment=3D printing slicer for Bambu Lab printers
            Exec=bambu-studio
            Icon=${bambuStudio}/share/icons/hicolor/256x256/apps/bambu-studio.png
            Terminal=false
            Type=Application
            Categories=Graphics;Engineering;3DGraphics;
          '';
        }
        {
          home.packages = pkgs.lib.mkAfter [pkgs.mesa];
        }
      ]
  );
}
