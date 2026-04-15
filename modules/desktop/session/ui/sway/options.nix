{lib, ...}: {
  options.user.ui.sway = {
    enable = lib.mkEnableOption "Sway wayland compositor";

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra Sway configuration appended to the generated config.";
    };
  };
}
