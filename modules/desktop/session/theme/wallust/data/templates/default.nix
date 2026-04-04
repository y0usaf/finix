# Shared wallust templates for NixOS and Darwin
# These use Jinja2 syntax: {{ color0 }}, {{ background | red }}, etc.
{lib}: let
  zellij = import ./zellij.nix {inherit lib;};
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
  mkWallustConfig = import ./wallust-config.nix {inherit lib;};

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

  # Obsidian Shimmering Focus theme colors
  obsidianColors = import ./obsidian-colors.nix;

  # gpui-shell theme colors
  gpuishellTheme = import ./gpuishell-theme.nix;

  # Termvide terminal theme
  termvideTheme = import ./termvide-theme.nix;

  # Termvide live OSC palette updater
  termvideOsc = import ./termvide-osc.nix;
}
