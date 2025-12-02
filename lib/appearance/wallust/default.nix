# Shared wallust configuration for NixOS and Darwin
# Provides colorschemes, templates, file definitions, and wt script
{lib}: let
  colorschemes = import ./colorschemes;
  templates = import ./templates {inherit lib;};
in {
  inherit colorschemes templates;

  # Generate wallust config files (path -> content)
  # Can be used by both hjem and home-manager
  mkFiles = {
    zjstatusEnabled ? false,
    discordStable ? false,
    discordVesktop ? false,
  }: {
    # Main config
    ".config/wallust/wallust.toml" = templates.mkWallustConfig {
      inherit discordStable discordVesktop;
    };

    # Colorschemes
    ".config/wallust/colorschemes/dopamine.json" = builtins.toJSON colorschemes.dopamine;
    ".config/wallust/colorschemes/sunset-red.json" = builtins.toJSON colorschemes.sunset-red;
    ".config/wallust/colorschemes/golden.json" = builtins.toJSON colorschemes.golden;

    # Shared CSS variables template
    ".config/wallust/templates/colors.css" = templates.colorsCss;

    # Pywal-compatible colors.json for pywalfox
    ".config/wallust/templates/colors.json" = templates.pywalColorsJson;

    # Foot terminal colors
    ".config/wallust/templates/foot-colors.ini" = templates.footColors;

    # Zellij templates
    ".config/wallust/templates/zellij-config.kdl" = templates.mkZellijConfigTemplate {inherit zjstatusEnabled;};
    ".config/wallust/templates/zellij-layout.kdl" = templates.zjstatusLayout;

    # Discord quickCss template
    ".config/wallust/templates/discord-quickcss.css" = templates.discordQuickCss;
  };

  # wt script text - wraps wallust with pywalfox update
  # browserBinary: which browser to update (librewolf, firefox)
  mkWtScriptText = {browserBinary ? "librewolf"}: ''
    if [ -z "''${1:-}" ]; then
      echo "Usage: wt <command> [args...]"
      echo "Commands: cs <colorscheme>, theme <name>, run <image>"
      exit 1
    fi

    # Pass all args to wallust
    wallust "$@"

    # Brief delay for file write (avoid race conditions)
    sleep 0.5

    # Update pywalfox
    pywalfox --browser ${browserBinary} update
  '';

  # Startup script to apply default theme
  mkStartupScript = {
    wallustBin,
    defaultTheme,
  }: ''
    # Ensure output directories exist (wallust templates write here)
    mkdir -p ~/.config/zellij/layouts
    mkdir -p ~/.cache/wal
    mkdir -p ~/.cache/wallust
    mkdir -p ~/.config/Vencord/settings
    mkdir -p ~/.config/vesktop/settings

    ${wallustBin} ${
      if builtins.hasAttr defaultTheme colorschemes
      then "cs ~/.config/wallust/colorschemes/${defaultTheme}.json"
      else "theme ${defaultTheme}"
    }
  '';
}
