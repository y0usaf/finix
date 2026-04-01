{lib, ...}: {
  options.user.ui.mangowc = {
    enable = lib.mkEnableOption "MangoWC wayland compositor";
  };
}
