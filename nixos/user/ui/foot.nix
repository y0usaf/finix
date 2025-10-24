{
  config,
  lib,
  pkgs,
  ...
}: let
  computedFontSize = toString (config.user.appearance.baseFontSize * 1.33);
  mainFontName = config.user.ui.fonts.mainFontName;
  fallbackFontNames = ["Symbols Nerd Font" config.user.ui.fonts.backup.name config.user.ui.fonts.emoji.name];
  mainFontConfig =
    "${mainFontName}:size=${computedFontSize}, "
    + lib.concatStringsSep ", " (map (name: "${name}:size=${computedFontSize}") fallbackFontNames);
  footConfig = {
    main = {
      term = "xterm-256color";
      font = mainFontConfig;
      dpi-aware = "yes";
    };
    cursor = {
      style = "underline";
      blink = "no";
    };
    mouse = {
      hide-when-typing = "no";
      alternate-scroll-mode = "yes";
    };
    colors = {
      alpha = config.user.appearance.opacity;
      background = "000000";
      foreground = "ffffff";
      regular0 = "000000";
      regular1 = "ff0000";
      regular2 = "00ff00";
      regular3 = "ffff00";
      regular4 = "1e90ff";
      regular5 = "ff00ff";
      regular6 = "00ffff";
      regular7 = "ffffff";
      bright0 = "808080";
      bright1 = "ff0000";
      bright2 = "00ff00";
      bright3 = "ffff00";
      bright4 = "1e90ff";
      bright5 = "ff00ff";
      bright6 = "00ffff";
      bright7 = "ffffff";
    };
    key-bindings = {
      clipboard-copy = "Control+c XF86Copy";
      clipboard-paste = "Control+v XF86Paste";
    };
  };
in {
  options.user.ui.foot = {
    enable = lib.mkEnableOption "foot terminal emulator";
  };
  config = lib.mkIf config.user.ui.foot.enable {
    environment.systemPackages = [
      pkgs.foot
    ];
    usr = {
      files.".config/foot/foot.ini" = {
        clobber = true;
        generator = lib.generators.toINI {};
        value = footConfig;
      };
    };
  };
}
