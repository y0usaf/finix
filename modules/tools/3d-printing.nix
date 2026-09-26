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
      (pkgs.orca-slicer.override {
        withNvidiaGLWorkaround = true;
        opencv = pkgs.opencv.override {enableCuda = false;};
      })
      (pkgs.bambu-studio.override {
        withNvidiaGLWorkaround = true;
        opencv = pkgs.opencv.override {enableCuda = false;};
      })
    ];
  };
}
