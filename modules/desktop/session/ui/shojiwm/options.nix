{lib, ...}: {
  options.user.ui.shojiwm = {
    enable = lib.mkEnableOption "ShojiWM wayland compositor";
  };
}
