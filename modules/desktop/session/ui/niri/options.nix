{lib, ...}: {
  options.user.ui.niri = {
    enable = lib.mkEnableOption "Niri wayland compositor";

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra KDL configuration appended to the generated config.";
    };
  };
}
