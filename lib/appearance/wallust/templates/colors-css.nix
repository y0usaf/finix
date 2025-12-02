# Shared CSS variables template - importable by any CSS file
# Output: ~/.cache/wallust/colors.css
''
  /* Wallust generated colors - @import this file for dynamic theming */
  :root {
    /* Terminal palette */
    --color0: {{ color0 }};
    --color1: {{ color1 }};
    --color2: {{ color2 }};
    --color3: {{ color3 }};
    --color4: {{ color4 }};
    --color5: {{ color5 }};
    --color6: {{ color6 }};
    --color7: {{ color7 }};
    --color8: {{ color8 }};
    --color9: {{ color9 }};
    --color10: {{ color10 }};
    --color11: {{ color11 }};
    --color12: {{ color12 }};
    --color13: {{ color13 }};
    --color14: {{ color14 }};
    --color15: {{ color15 }};

    /* Special colors */
    --background: {{ background }};
    --foreground: {{ foreground }};
    --cursor: {{ cursor }};

    /* Semantic aliases */
    --bg: {{ background }};
    --fg: {{ foreground }};
    --black: {{ color0 }};
    --red: {{ color1 }};
    --green: {{ color2 }};
    --yellow: {{ color3 }};
    --blue: {{ color4 }};
    --magenta: {{ color5 }};
    --cyan: {{ color6 }};
    --white: {{ color7 }};
    --bright-black: {{ color8 }};
    --bright-red: {{ color9 }};
    --bright-green: {{ color10 }};
    --bright-yellow: {{ color11 }};
    --bright-blue: {{ color12 }};
    --bright-magenta: {{ color13 }};
    --bright-cyan: {{ color14 }};
    --bright-white: {{ color15 }};
  }
''
