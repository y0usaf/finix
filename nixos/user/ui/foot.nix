{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config) user;
  userUi = user.ui;
  userAppearance = user.appearance;
  uiFonts = userUi.fonts;
  computedFontSize = toString userAppearance.termFontSize;
in {
  options.user.ui.foot = {
    enable = lib.mkEnableOption "foot terminal emulator";
  };
  config = lib.mkIf userUi.foot.enable {
    environment.systemPackages = [
      pkgs.foot
    ];
    usr.files.".config/foot/foot.ini" = {
      clobber = true;
      # Foot config - colors loaded dynamically from wallust via include (cache-only theming)
      text = ''
        include=~/.cache/wallust/colors_foot.ini

        [main]
        term=xterm-256color
        font=${"${uiFonts.mainFontName}:size=${computedFontSize}, "
          + lib.concatStringsSep ", " (map (name: "${name}:size=${computedFontSize}") [
            "Symbols Nerd Font"
            uiFonts.backup.name
            uiFonts.emoji.name
          ])}
        dpi-aware=yes

        [cursor]
        style=underline
        blink=no

        [mouse]
        hide-when-typing=no
        alternate-scroll-mode=yes

        [colors-dark]
        alpha=${toString userAppearance.opacity}

        [key-bindings]
        clipboard-copy=Control+c XF86Copy
        clipboard-paste=Control+v XF86Paste
      '';
    };
  };
}
