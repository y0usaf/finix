{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config) user;
  userUi = user.ui;
  uiFonts = userUi.fonts;
  computedFontSize = toString user.appearance.termFontSize;
in {
  options.user.ui.foot = {
    enable = lib.mkEnableOption "foot terminal emulator";
    lineHeight = lib.mkOption {
      type = lib.types.str;
      default = "24px";
      description = "Foot line height";
    };
  };
  config = lib.mkIf userUi.foot.enable {
    environment.systemPackages = [
      pkgs.foot
    ];
    manzil.users."${config.user.name}".files.".config/foot/foot.ini" = {
      generator = lib.generators.toINI {};
      value = {
        main = {
          include = user.appearance.wallust.targets.foot-colors.target;
          term = "xterm-256color";
          font =
            "${uiFonts.mainFontName}:size=${computedFontSize}, "
            + lib.concatStringsSep ", " (map (name: "${name}:size=${computedFontSize}") [
              "Symbols Nerd Font"
              uiFonts.backup.name
              uiFonts.emoji.name
            ]);
          "bold-text-in-bright" = "yes";
          "dpi-aware" = "yes";
          "line-height" = userUi.foot.lineHeight;
        };

        bell = {
          urgent = "yes";
        };

        cursor = {
          style = "underline";
          blink = "no";
        };

        mouse = {
          "hide-when-typing" = "no";
          "alternate-scroll-mode" = "yes";
        };

        "colors-dark" = {
          alpha = "0.82";
          "alpha-mode" = "matching";
        };

        "key-bindings" = {
          "clipboard-copy" = "Control+c XF86Copy";
          "clipboard-paste" = "Control+v XF86Paste";
        };
      };
    };
  };
}
