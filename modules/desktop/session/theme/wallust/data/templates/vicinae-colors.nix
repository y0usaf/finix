# Vicinae theme template using wallust variables
''
  [meta]
  name = "Wallust Auto"
  description = "Auto-generated theme from Wallust colors"
  variant = "dark"
  inherits = "vicinae-dark"

  [colors.core]
  # Use wallust colors: cursor is accent, color0 is black/background
  accent = "{{ cursor }}"
  background = "{{ color0 }}"
  foreground = "{{ color7 }}"

  [colors.accents.color]
  # Use wallust's ANSI color palette
  red = "{{ color1 }}"
  green = "{{ color2 }}"
  yellow = "{{ color3 }}"
  blue = "{{ color4 }}"
  purple = "{{ color5 }}"
  cyan = "{{ color6 }}"
''
