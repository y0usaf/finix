{lib, ...}: {
  options.user.ui.hyprland = {
    enable = lib.mkEnableOption "Hyprland window manager";
  };
}
