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
  pkgs,
  lib,
  profile,
  ...
}: let
  cfg = config.modules.ui.foot;

  # Calculate the scaled font size based on the profile's base font size.
  computedFontSize = toString (profile.modules.appearance.baseFontSize * 1.33);

  # Get the main font name from the profile's font configuration
  mainFontName = builtins.elemAt (builtins.elemAt profile.modules.appearance.fonts.main 0) 1;

  # Get fallback font names
  fallbackFontNames = map (x: builtins.elemAt x 1) profile.modules.appearance.fonts.fallback;

  # Build the main font configuration string, including the fallback fonts.
  mainFontConfig =
    "${mainFontName}:size=${computedFontSize}, "
    + lib.concatStringsSep ", " (map (name: "${name}:size=${computedFontSize}") fallbackFontNames);

  # Main terminal settings: terminal type, font, and DPI awareness.
  footMainSettings = {
    term = "xterm-256color";
    font = mainFontConfig;
    dpi-aware = "yes";
  };

  # Cursor settings: style and blink behavior.
  footCursorSettings = {
    style = "underline";
    blink = "no";
  };

  # Mouse behavior settings: typing behavior and scroll mode.
  footMouseSettings = {
    hide-when-typing = "no";
    alternate-scroll-mode = "yes";
  };

  # Color scheme settings, including both the regular and bright color palettes.
  footColorSettings = {
    alpha = 0.01;
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

  # Key bindings: assign shortcuts for clipboard copy and paste actions.
  footKeyBindings = {
    clipboard-copy = "Control+c XF86Copy";
    clipboard-paste = "Control+v XF86Paste";
  };
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.modules.ui.foot = {
    enable = lib.mkEnableOption "foot terminal emulator";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Programs
    ###########################################################################
    programs.foot = {
      enable = true;

      settings = {
        main = footMainSettings;
        cursor = footCursorSettings;
        mouse = footMouseSettings;
        colors = footColorSettings;
        key-bindings = footKeyBindings;
      };
    };
  };
}
