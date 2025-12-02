# Wallust config template generator
{lib}: {
  extraTemplates ? "",
  discordStable ? false,
  discordVesktop ? false,
  niriEnabled ? false,
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

  # Pywal-compatible colors.json for pywalfox
  pywal-colors = { template = "colors.json", target = "~/.cache/wal/colors.json" }

  # Foot terminal colors (cache-only theming)
  foot-colors = { template = "foot-colors.ini", target = "~/.cache/wallust/colors_foot.ini" }

  # Zellij templates
  zellij-config = { template = "zellij-config.kdl", target = "~/.config/zellij/config.kdl" }
  zellij-layout = { template = "zellij-layout.kdl", target = "~/.config/zellij/layouts/zjstatus.kdl" }
  ${lib.optionalString discordStable ''
    # Discord stable (Vencord) quickCss
    discord-quickcss-vencord = { template = "discord-quickcss.css", target = "~/.config/Vencord/settings/quickCss.css" }
  ''}${lib.optionalString discordVesktop ''
    # Vesktop quickCss
    discord-quickcss-vesktop = { template = "discord-quickcss.css", target = "~/.config/vesktop/settings/quickCss.css" }
  ''}${lib.optionalString niriEnabled ''
    # Niri border colors (included via niri's include directive)
    niri-borders = { template = "niri-borders.kdl", target = "~/.cache/wallust/niri-borders.kdl" }
  ''}${extraTemplates}
''
