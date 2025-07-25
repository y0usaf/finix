{lib, ...}: {
  options.home.ui.niri = {
    enable = lib.mkEnableOption "Niri wayland compositor";
  };
}
