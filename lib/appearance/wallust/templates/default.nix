# Shared wallust templates for NixOS and Darwin
# These use Jinja2 syntax: {{ color0 }}, {{ background | red }}, etc.
{lib}: let
  zellij = import ./zellij.nix {inherit lib;};
  mkWallustConfig = import ./wallust-config.nix {inherit lib;};
in {
  # CSS variables
  colorsCss = import ./colors-css.nix;

  # Terminal colors
  footColors = import ./foot.nix;

  # Pywal JSON
  pywalColorsJson = import ./pywal.nix;

  # Wallust config generator
  inherit mkWallustConfig;

  # Zellij templates
  mkZellijConfigTemplate = zellij.mkConfigTemplate;
  zjstatusLayout = zellij.layout;
  zellijTheme = zellij.theme;

  # Discord/Vesktop
  discordQuickCss = import ./discord.nix;

  # MinimalImprovement compact theme (separate from quickCss)
  minimalImprovement = import ./minimal-improvement.nix;

  # Niri border colors (included via niri's include directive)
  niriBorders = import ./niri.nix;

  # AGS (Astal) color variables
  agsColors = import ./ags.nix;
}
