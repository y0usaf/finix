{lib, ...}: {
  options.user.ui.vicinae = {
    enable = lib.mkEnableOption "Vicinae launcher";

    scale = lib.mkOption {
      type = lib.types.float;
      default = 1.5;
      description = "UI scaling factor for vicinae. Multiplied by the base font size (10.5).";
    };

    theme = lib.mkOption {
      type = lib.types.str;
      default = "wallust-auto";
      description = "Vicinae theme. Use 'wallust-auto' to generate a theme from wallust colors.";
    };

    extraConfig = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Extra configuration to merge into vicinae.json.";
    };
  };
}
