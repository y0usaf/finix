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
    niriEnabled ? false,
  }: {
    # Main config
    ".config/wallust/wallust.toml" = templates.mkWallustConfig {
      inherit discordStable discordVesktop niriEnabled;
    };

    # Colorschemes
    ".config/wallust/colorschemes/dopamine.json" = builtins.toJSON colorschemes.dopamine;
    ".config/wallust/colorschemes/red.json" = builtins.toJSON colorschemes.red;
    ".config/wallust/colorschemes/p4g.json" = builtins.toJSON colorschemes.p4g;

    # Shared CSS variables template
    ".config/wallust/templates/colors.css" = templates.colorsCss;

    # Pywal-compatible colors.json for pywalfox
    ".config/wallust/templates/colors.json" = templates.pywalColorsJson;

    # Foot terminal colors
    ".config/wallust/templates/foot-colors.ini" = templates.footColors;

    # Shell colors (hex variables for runtime ANSI conversion)
    ".config/wallust/templates/shell-colors.sh" = templates.shellColors;

    # Zellij templates
    ".config/wallust/templates/zellij-config.kdl" = templates.mkZellijConfigTemplate {inherit zjstatusEnabled;};
    ".config/wallust/templates/zellij-layout.kdl" = templates.zjstatusLayout;

    # Discord quickCss template
    ".config/wallust/templates/discord-quickcss.css" = templates.discordQuickCss;

    # Niri border colors template
    ".config/wallust/templates/niri-borders.kdl" = templates.niriBorders;

    # GTK CSS color definitions
    ".config/wallust/templates/gtk-colors.css" = templates.gtkColors;
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
    mkdir -p ~/.config/ags

    ${wallustBin} ${
      if builtins.hasAttr defaultTheme colorschemes
      then "cs ~/.config/wallust/colorschemes/${defaultTheme}.json"
      else "theme ${defaultTheme}"
    }
  '';
}
