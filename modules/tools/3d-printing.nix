{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.tools."3d-printing" = {
    enable = lib.mkEnableOption "3D printing tools (OrcaSlicer + BambuStudio)";
  };
  config = lib.mkIf config.user.tools."3d-printing".enable {
    environment.systemPackages = [
      # withNvidiaGLWorkaround forces Mesa/Zink for OpenGL to fix blank 3D
      # viewport on Wayland when global __GLX_VENDOR_LIBRARY_NAME=nvidia is set.
      # opencv must be overridden to a non-CUDA build because nixpkgs.config.cudaSupport=true
      # causes the default opencv cmake config to require nvcc at configure time.
      (pkgs.orca-slicer.override {
        withNvidiaGLWorkaround = true;
        opencv = pkgs.opencv.override { enableCuda = false; };
      })
      (pkgs.bambu-studio.override {
        withNvidiaGLWorkaround = true;
        opencv = pkgs.opencv.override { enableCuda = false; };
      })
    ];
  };
}
