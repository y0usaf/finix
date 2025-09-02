{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.ui.foot;
  computedFontSize = toString (config.home.core.appearance.baseFontSize * 1.33);
  mainFontName = (builtins.elemAt config.home.core.appearance.fonts.main 0).name;
  fallbackFontNames = map (x: x.name) config.home.core.appearance.fonts.fallback;
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
      alpha = 1.0 - config.home.core.appearance.opacity;
      background = "0f0f0f";
      foreground = "ffffff";
      # Black/Gray
      regular0 = "000000";
      bright0 = "808080";
      # Red/Pink (errors)
      regular1 = "ff0064";
      bright1 = "ff007f";
      # Green (success)
      regular2 = "00ff64";
      bright2 = "00ff7f";
      # Yellow/Orange
      regular3 = "ff6400";
      bright3 = "ff7f00";
      # Blue/Cyan (highlights)
      regular4 = "00c8ff";
      bright4 = "00dcff";
      # Magenta/Purple
      regular5 = "c800ff";
      bright5 = "dc00ff";
      # Cyan/Teal (active states)
      regular6 = "00ff96";
      bright6 = "00ffaa";
      # White
      regular7 = "b4b4b4";
      bright7 = "ffffff";
    };
    key-bindings = {
      clipboard-copy = "Control+c XF86Copy";
      clipboard-paste = "Control+v XF86Paste";
    };
  };
in {
  options.home.ui.foot = {
    enable = lib.mkEnableOption "foot terminal emulator";
  };
  config = lib.mkIf cfg.enable {
    hjem.users.${config.user.name} = {
      packages = with pkgs; [
        foot
      ];
      files.".config/foot/foot.ini" = {
        clobber = true;
        text = lib.mkAfter (lib.generators.toINI {} footConfig);
      };
    };
  };
}
