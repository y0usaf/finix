{lib, ...}: {
  options.user.ui.niri = {
    enable = lib.mkEnableOption "Niri wayland compositor";

    blur = {
      enable = lib.mkEnableOption "window blur effects" // {default = true;};
      passes = lib.mkOption {
        type = lib.types.int;
        default = 5;
        description = "Number of blur passes (higher = stronger blur).";
      };
      radius = lib.mkOption {
        type = lib.types.int;
        default = 5;
        description = "Blur radius in pixels.";
      };
      noise = lib.mkOption {
        type = lib.types.int;
        default = 0;
        description = "Noise intensity for blur effect.";
      };
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra KDL configuration appended to the generated config.";
    };
  };
}
