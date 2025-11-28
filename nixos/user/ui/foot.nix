{
  config,
  lib,
  pkgs,
  ...
}: let
  computedFontSize = toString (config.user.appearance.baseFontSize * 1.33);
  inherit (config.user.ui.fonts) mainFontName;
  fallbackFontNames = ["Symbols Nerd Font" config.user.ui.fonts.backup.name config.user.ui.fonts.emoji.name];
  mainFontConfig =
    "${mainFontName}:size=${computedFontSize}, "
    + lib.concatStringsSep ", " (map (name: "${name}:size=${computedFontSize}") fallbackFontNames);
  # Foot config - colors loaded dynamically from wallust via include (cache-only theming)
  footConfigText = ''
    include=~/.cache/wallust/colors_foot.ini

    [main]
    term=xterm-256color
    font=${mainFontConfig}
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
      text = footConfigText;
    };
  };
}
