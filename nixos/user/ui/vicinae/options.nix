{lib, ...}: {
  options.user.ui.vicinae = {
    enable = lib.mkEnableOption "Vicinae launcher";

    theme = lib.mkOption {
      type = lib.types.str;
      default = "wallust-auto";
      description = "Vicinae theme. Use 'wallust-auto' to generate a theme from wallust colors.";
    };

    extraConfig = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Extra configuration appended to the generated vicinae theme.";
    };
  };
}
