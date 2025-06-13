###############################################################################
# Foot Terminal Configuration
# Terminal emulator with focus on minimalism and performance
# - Terminal styling and appearance
# - Key bindings for clipboard operations
# - Font configuration with fallback support
# - Cursor and mouse behavior settings
###############################################################################
{
  config,
  lib,
  pkgs,
  hostHjem,
  ...
}: let
  cfg = config.cfg.hjome.ui.foot;

  # Calculate the scaled font size based on the hostHjem's base font size.
  computedFontSize = toString (hostHjem.cfg.hjome.core.appearance.baseFontSize * 1.33);

  # Get the main font name from the hostHjem's font configuration
  mainFontName = (builtins.elemAt hostHjem.cfg.hjome.core.appearance.fonts.main 0).name;

  # Get fallback font names
  fallbackFontNames = map (x: x.name) hostHjem.cfg.hjome.core.appearance.fonts.fallback;

  # Build the main font configuration string, including the fallback fonts.
  mainFontConfig =
    "${mainFontName}:size=${computedFontSize}, "
    + lib.concatStringsSep ", " (map (name: "${name}:size=${computedFontSize}") fallbackFontNames);

  # Foot configuration using your actual foot.ini settings
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
      alpha = 0;
      background = "000000";
      foreground = "ffffff";

      # Regular color palette
      regular0 = "000000"; # black
      regular1 = "ff0000"; # red
      regular2 = "00ff00"; # green
      regular3 = "ffff00"; # yellow
      regular4 = "1e90ff"; # blue
      regular5 = "ff00ff"; # magenta
      regular6 = "00ffff"; # cyan
      regular7 = "ffffff"; # white

      # Bright color palette
      bright0 = "808080"; # bright black
      bright1 = "ff0000"; # bright red
      bright2 = "00ff00"; # bright green
      bright3 = "ffff00"; # bright yellow
      bright4 = "1e90ff"; # bright blue
      bright5 = "ff00ff"; # bright magenta
      bright6 = "00ffff"; # bright cyan
      bright7 = "ffffff"; # bright white
    };

    key-bindings = {
      clipboard-copy = "Control+c XF86Copy";
      clipboard-paste = "Control+v XF86Paste";
    };
  };
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.hjome.ui.foot = {
    enable = lib.mkEnableOption "foot terminal emulator";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    packages = with pkgs; [
      foot
    ];

    ###########################################################################
    # Configuration Files
    ###########################################################################
    files."${config.xdg.configDirectory}/foot/foot.ini".text = lib.mkAfter (lib.generators.toINI {} footConfig);
  };
}
