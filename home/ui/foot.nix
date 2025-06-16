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
  ...
}: let
  cfg = config.home.ui.foot;

  # Calculate the scaled font size based on the appearance configuration.
  computedFontSize = toString (config.home.core.appearance.baseFontSize * 1.33);

  # Get the main font name from the appearance configuration
  mainFontName = (builtins.elemAt config.home.core.appearance.fonts.main 0).name;

  # Get fallback font names
  fallbackFontNames = map (x: x.name) config.home.core.appearance.fonts.fallback;

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
  options.home.ui.foot = {
    enable = lib.mkEnableOption "foot terminal emulator";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    users.users.y0usaf.maid.packages = with pkgs; [
      foot
    ];

    ###########################################################################
    # Configuration Files
    ###########################################################################
    users.users.y0usaf.maid.file.xdg_config."foot/foot.ini".text = lib.mkAfter (lib.generators.toINI {} footConfig);
  };
}
