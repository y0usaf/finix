# Wallust config template generator
{lib}: {
  extraTemplates ? "",
  discordStable ? false,
  discordVesktop ? false,
  discordMinimalImprovement ? false,
  niriEnabled ? false,
  agsEnabled ? false,
}: ''
  backend = "fastresize"
  color_space = "lch"
  palette = "dark"
  check_contrast = true

  [templates]
  # Shared CSS variables - importable by GTK, browsers, Discord, etc.
  colors-css = { template = "colors.css", target = "~/.cache/wallust/colors.css" }

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
  ''}${lib.optionalString discordMinimalImprovement ''
    # MinimalImprovement compact theme (toggleable in Vencord themes)
    minimal-improvement = { template = "minimal-improvement.css", target = "~/.config/Vencord/themes/MinimalImprovement.theme.css" }
    minimal-improvement-vesktop = { template = "minimal-improvement.css", target = "~/.config/vesktop/themes/MinimalImprovement.theme.css" }
  ''}${lib.optionalString niriEnabled ''
    # Niri border colors (included via niri's include directive)
    niri-borders = { template = "niri-borders.kdl", target = "~/.cache/wallust/niri-borders.kdl" }
  ''}${lib.optionalString agsEnabled ''
    # AGS (Astal) color variables
    ags-colors = { template = "ags-colors.css", target = "~/.cache/wallust/ags-colors.css" }
  ''}${extraTemplates}
''
