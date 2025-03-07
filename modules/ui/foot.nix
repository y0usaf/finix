#===============================================================================
#                      🖥️ Foot Terminal Configuration 🖥️
#===============================================================================
# 🎨 Terminal styling
# ⌨️ Key bindings
# 🔤 Font settings
# 🎯 Cursor config
#===============================================================================
{
  config,
  pkgs,
  lib,
  profile,
  ...
}:
#######################################################################
#                   COMPUTE FONT CONFIGURATION PARAMETERS
#######################################################################
let
  # Calculate the scaled font size based on the profile's base font size.
  computedFontSize = toString (profile.baseFontSize * 1.33);

  # Get the main font name from the profile's font configuration
  mainFontName = builtins.elemAt (builtins.elemAt profile.fonts.main 0) 1;

  # Get fallback font names
  fallbackFontNames = map (x: builtins.elemAt x 1) profile.fonts.fallback;

  # Build the main font configuration string, including the fallback fonts.
  mainFontConfig =
    "${mainFontName}:size=${computedFontSize}, "
    + lib.concatStringsSep ", " (map (name: "${name}:size=${computedFontSize}") fallbackFontNames);

  #######################################################################
  #                    DEFINE INDIVIDUAL FOOT SETTINGS
  #######################################################################

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

  # Key bindings: assign shortcuts for clipboard copy and paste actions.
  footKeyBindings = {
    clipboard-copy = "Control+c XF86Copy";
    clipboard-paste = "Control+v XF86Paste";
  };
  #######################################################################
  #             COMBINE ALL FOOT TERMINAL SETTINGS INTO A SINGLE OBJECT
  #######################################################################
in {
  ###########################################################################
  # Foot Terminal Program Configuration
  #   Enables foot and defines all related terminal settings.
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
}
