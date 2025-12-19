# Wallust config template generator
{lib}: {
  extraTemplates ? "",
  niriEnabled ? false,
  vicinaeEnabled ? false,
  cmusEnabled ? false,
}: ''
  backend = "fastresize"
  color_space = "lch"
  palette = "dark"
  check_contrast = true

  [templates]
  # Web CSS variables - for browsers, Electron apps, etc.
  colors-css = { template = "colors.css", target = "~/.cache/wallust/colors.css" }

  # GTK CSS colors - for AGS and other GTK apps
  gtk-colors = { template = "gtk-colors.css", target = "~/.cache/wallust/gtk-colors.css" }

  # Shell variables (hex colors for cat-fetch and other shell apps)
  shell-colors = { template = "shell-colors.sh", target = "~/.cache/wallust/shell-colors.sh" }

  # Pywal-compatible colors.json for pywalfox
  pywal-colors = { template = "colors.json", target = "~/.cache/wal/colors.json" }

  # Foot terminal colors (cache-only theming)
  foot-colors = { template = "foot-colors.ini", target = "~/.cache/wallust/colors_foot.ini" }

  # Zellij templates
  zellij-config = { template = "zellij-config.kdl", target = "~/.config/zellij/config.kdl" }
  zellij-layout = { template = "zellij-layout.kdl", target = "~/.config/zellij/layouts/zjstatus.kdl" }

  # Discord theme colors (hot-reloadable via Vencord)
  discord-colors = { template = "discord-colors.css", target = "~/.config/Vencord/themes/wallust-colors.css" }
  ${lib.optionalString niriEnabled ''
    # Niri border colors (included via niri's include directive)
    niri-borders = { template = "niri-borders.kdl", target = "~/.cache/wallust/niri-borders.kdl" }
  ''}${lib.optionalString vicinaeEnabled ''
    # Vicinae theme (auto-generated from wallust colors)
    vicinae-colors = { template = "vicinae-colors.toml", target = "~/.local/share/vicinae/themes/wallust-auto.toml" }
  ''}${lib.optionalString cmusEnabled ''
    # cmus colorscheme (uses fixed ANSI indices, palette varies per wallust theme)
    cmus-colors = { template = "cmus-colors.theme", target = "~/.config/cmus/colorschemes/wallust-auto.theme" }
  ''}${extraTemplates}
''
