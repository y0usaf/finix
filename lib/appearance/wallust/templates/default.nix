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

  # Shell variables (hex colors for runtime ANSI conversion)
  shellColors = import ./shell-colors.nix;

  # Pywal JSON
  pywalColorsJson = import ./pywal.nix;

  # Wallust config generator
  inherit mkWallustConfig;

  # Zellij templates
  mkZellijConfigTemplate = zellij.mkConfigTemplate;
  zjstatusLayout = zellij.layout;
  zellijTheme = zellij.theme;

  # Discord theme colors (hot-reloadable, imported by quickCSS)
  discordColors = import ./discord-colors.nix;

  # Niri border colors (included via niri's include directive)
  niriBorders = import ./niri.nix;

  # Vicinae theme colors
  vicinaeColors = import ./vicinae-colors.nix;

  # cmus colorscheme
  cmusColors = import ./cmus-colors.nix;

  # GTK CSS color definitions (for AGS and other GTK apps)
  gtkColors = import ./gtk-colors.nix;
}
