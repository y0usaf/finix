# Vicinae theme template using wallust variables
''
  [meta]
  name = "Wallust Auto"
  description = "Auto-generated theme from Wallust colors"
  variant = "dark"
  inherits = "vicinae-dark"

  [colors.core]
  # Primary accent color - uses wallust's primary accent
  accent = "{{ colors.primary }}"
  # Background uses wallust's background
  background = "{{ colors.background }}"
  # Foreground text color
  foreground = "{{ colors.foreground }}"

  [colors.accents.color]
  # Use wallust's color palette
  red = "{{ colors.red }}"
  green = "{{ colors.green }}"
  yellow = "{{ colors.yellow }}"
  blue = "{{ colors.blue }}"
  purple = "{{ colors.purple }}"
  cyan = "{{ colors.cyan }}"
''
