{
  config,
  lib,
  pkgs,
  ...
}: let
  computedFontSize = toString config.user.appearance.termFontSize;
in {
  options.user.ui.foot = {
    enable = lib.mkEnableOption "foot terminal emulator";
  };
  config = lib.mkIf config.user.ui.foot.enable {
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
        font=${"${config.user.ui.fonts.mainFontName}:size=${computedFontSize}, "
          + lib.concatStringsSep ", " (map (name: "${name}:size=${computedFontSize}") [
            "Symbols Nerd Font"
            config.user.ui.fonts.backup.name
            config.user.ui.fonts.emoji.name
          ])}
        dpi-aware=yes

        [cursor]
        style=underline
        blink=no

        [mouse]
        hide-when-typing=no
        alternate-scroll-mode=yes

        [colors]
        alpha=${toString config.user.appearance.opacity}

        [key-bindings]
        clipboard-copy=Control+c XF86Copy
        clipboard-paste=Control+v XF86Paste
      '';
    };
  };
}
