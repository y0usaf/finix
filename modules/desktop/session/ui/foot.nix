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
  };
  config = lib.mkIf userUi.foot.enable {
    environment.systemPackages = [
      pkgs.foot
    ];
    manzil.users."${config.user.name}".files.".config/foot/foot.ini" = {
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
        # Center the terminal grid when the compositor gives foot a window size
        # that is not an exact multiple of the cell height/width. Without this,
        # foot anchors the grid top-left and puts the leftover pixels on the
        # bottom/right, which shows up as a tiny gap below Zellij's bottom bar.
        pad=0x0 center

        [cursor]
        style=underline
        blink=no

        [mouse]
        hide-when-typing=no
        alternate-scroll-mode=yes

        [colors-dark]
        alpha=0.82
        alpha-mode=matching

        [key-bindings]
        clipboard-copy=Control+c XF86Copy
        clipboard-paste=Control+v XF86Paste
      '';
    };
  };
}
