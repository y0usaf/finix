{
  config,
  lib,
  pkgs,
  host,
  ...
}: {
  options.cfg.programs.bambu.enable = lib.mkEnableOption "Bambu Studio";

  config = lib.mkIf config.cfg.programs.bambu.enable (lib.mkMerge [
    {
    home.packages = let
      _ = lib.assertMsg (builtins.pathExists "${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json")
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

      # Create a wrapper script that sets the correct environment variables
      bambuStudioWrapper = pkgs.writeShellScriptBin "bambu-studio" ''
        # Use the mesa package path for the EGL vendor file
        MESA_PATH="${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json"

        if [ ! -f "$MESA_PATH" ]; then
          echo "\n\033[1;31mFATAL: Mesa EGL vendor file is required for Bambu Studio to run.\033[0m"
          echo "Expected at: $MESA_PATH"
          echo "This package will not run without it. Please ensure mesa is available."
          exit 1
        fi

        # Launch Bambu Studio with the correct environment variables
        __EGL_VENDOR_LIBRARY_FILENAMES=$MESA_PATH \
        WEBKIT_FORCE_COMPOSITING_MODE=1 \
        WEBKIT_DISABLE_COMPOSITING_MODE=1 \
        WEBKIT_DISABLE_DMABUF_RENDERER=1 \
        ${bambuStudio}/bin/bambu-studio "$@"
      '';
    in [bambuStudioWrapper];
  }
  # Ensure mesa is always available when Bambu Studio is enabled
  {
    home.packages = pkgs.lib.mkAfter [ pkgs.mesa ];
  }
]);
}

