{lib, ...}: {
  options.home.ui.hyprland = {
    enable = lib.mkEnableOption "Hyprland window manager";
    flake = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to use Hyprland from flake inputs instead of nixpkgs";
      };
    };
    hy3 = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to enable the hy3 tiling layout plugin";
      };
    };
    group = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to enable the group layout mode";
      };
    };
  };
}
