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
  globals,
  ...
}: {
  programs.foot = {
    enable = true;

    settings = {
      main = {
        term = "xterm-256color";
        font = "monospace:size=16";
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

        regular0 = "000000"; # black
        regular1 = "ff0000"; # red
        regular2 = "00ff00"; # green
        regular3 = "ffff00"; # yellow
        regular4 = "1e90ff"; # blue
        regular5 = "ff00ff"; # magenta
        regular6 = "00ffff"; # cyan
        regular7 = "ffffff"; # white

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
  };
}
