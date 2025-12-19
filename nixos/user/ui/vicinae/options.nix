{lib, ...}: {
  options.user.ui.vicinae = {
    enable = lib.mkEnableOption "Vicinae launcher";

    scale = lib.mkOption {
      type = lib.types.float;
      default = 1.5;
      description = "UI scaling factor for vicinae. Multiplied by the base font size (10.5).";
    };

    extraConfig = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = "Extra configuration to merge into vicinae.json.";
    };
  };
}
