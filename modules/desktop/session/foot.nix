{
  config,
  lib,
  pkgs,
  ...
}: let
  uiFonts = config.user.ui.fonts;
in {
  options.user.ui.foot = {
    lineHeight = lib.mkOption {
      type = lib.types.str;
      default = "24px";
      description = "Foot line height";
    };
  };
  config = {
    environment.systemPackages = [
      pkgs.foot
    ];
    manzil.users."${config.user.name}".files.".config/foot/foot.ini" = {
      generator = lib.generators.toINI {};
      value = {
        main = {
          include = "~/.cache/wallust/colors_foot.ini";
          term = "xterm-256color";
          font =
            "${uiFonts.mainFontName}:size=${toString config.user.appearance.termFontSize}, "
            + lib.concatStringsSep ", " (map (name: "${name}:size=${toString config.user.appearance.termFontSize}") [
              "Symbols Nerd Font"
              uiFonts.backup.name
              uiFonts.emoji.name
            ]);
          "bold-text-in-bright" = "yes";
          "dpi-aware" = "yes";
          "line-height" = config.user.ui.foot.lineHeight;
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
