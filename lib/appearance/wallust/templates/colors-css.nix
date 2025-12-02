# Shared CSS variables template - importable by any CSS file
# Output: ~/.config/wallust/colors.css
''
  /* Wallust generated colors - @import this file for dynamic theming */
  :root {
    /* Base terminal colors */
    --wallust-color0: {{ color0 }};
    --wallust-color1: {{ color1 }};
    --wallust-color2: {{ color2 }};
    --wallust-color3: {{ color3 }};
    --wallust-color4: {{ color4 }};
    --wallust-color5: {{ color5 }};
    --wallust-color6: {{ color6 }};
    --wallust-color7: {{ color7 }};
    --wallust-color8: {{ color8 }};
    --wallust-color9: {{ color9 }};
    --wallust-color10: {{ color10 }};
    --wallust-color11: {{ color11 }};
    --wallust-color12: {{ color12 }};
    --wallust-color13: {{ color13 }};
    --wallust-color14: {{ color14 }};
    --wallust-color15: {{ color15 }};

    /* Special colors */
    --wallust-background: {{ background }};
    --wallust-foreground: {{ foreground }};
    --wallust-cursor: {{ cursor }};

    /* Semantic aliases */
    --wallust-bg: {{ background }};
    --wallust-fg: {{ foreground }};
    --wallust-black: {{ color0 }};
    --wallust-red: {{ color1 }};
    --wallust-green: {{ color2 }};
    --wallust-yellow: {{ color3 }};
    --wallust-blue: {{ color4 }};
    --wallust-magenta: {{ color5 }};
    --wallust-cyan: {{ color6 }};
    --wallust-white: {{ color7 }};
    --wallust-bright-black: {{ color8 }};
    --wallust-bright-red: {{ color9 }};
    --wallust-bright-green: {{ color10 }};
    --wallust-bright-yellow: {{ color11 }};
    --wallust-bright-blue: {{ color12 }};
    --wallust-bright-magenta: {{ color13 }};
    --wallust-bright-cyan: {{ color14 }};
    --wallust-bright-white: {{ color15 }};
  }
''
