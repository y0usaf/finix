{lib, ...}: {
  options.user.ui.hyprland = {
    enable = lib.mkEnableOption "Hyprland window manager";
    group = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to enable the group layout mode";
      };
    };
  };
}
