{
  generators,
  lib,
  pkgs,
  ...
}: let
  schemes = import ./colorschemes.data.nix;

  targets = {
    "discord-colors.css" = [".config/Vencord/themes/palette.css" ".config/vesktop/themes/palette.css"];
    "foot-colors.ini" = [".cache/theme/foot.ini"];
    "gtk-colors.css" = [".cache/theme/gtk.css"];
    "monstar-theme" = [".cache/theme/monstar"];
  };

  scope = scheme: let
    hex = lib.removePrefix "#";
    channel = offset: value: toString (lib.fromHexString (builtins.substring offset 2 (hex value)));
  in {
    inherit generators;
    values = scheme.colors // scheme.special;
    filters = {
      strip = hex;
      red = channel 0;
      green = channel 2;
      blue = channel 4;
    };
  };

  templates = {
    "discord-colors.css" = import ./templates/discord-colors.data.nix;
    "foot-colors.ini" = import ./templates/foot-colors.data.nix;
    "gtk-colors.css" = import ./templates/gtk-colors.data.nix;
    "monstar-theme" = import ./templates/monstar-theme.data.nix;
    "osc.sh" = import ./templates/osc.data.nix;
  };

  instantiate = scheme: template: template (scope scheme);

  themes = pkgs.linkFarm "themes" (lib.concatLists (lib.mapAttrsToList (name: scheme:
    lib.mapAttrsToList (template: source: {
      name = "${name}/${template}";
      path = pkgs.writeText "${name}-${template}" (instantiate scheme source);
    })
    templates)
  schemes));

  gtkThemes = {
    dark = "Adwaita-dark";
    light = "Adwaita";
  };

  adwaitaDark = pkgs.writeTextDir "share/themes/Adwaita-dark/gtk-3.0/gtk.css" ''
    @import url("resource:///org/gtk/libgtk/theme/Adwaita/gtk-contained-dark.css");
  '';

  theme = pkgs.writeShellApplication {
    name = "theme";
    runtimeInputs = [pkgs.coreutils pkgs.dconf];
    text = ''
      case "''${1:-}" in
        ${lib.concatMapStringsSep "\n  " (name: "${name}) gtk=${gtkThemes.${name}} ;;") (builtins.attrNames schemes)}
        *)
          echo "usage: theme <${lib.concatStringsSep "|" (builtins.attrNames schemes)}>" >&2
          exit 1
          ;;
      esac
      dir=${themes}/$1

      place() {
        mkdir -p "$(dirname "$2")"
        install -m 644 "$1" "$2.new"
        mv -f "$2.new" "$2"
      }
      ${lib.concatStrings (lib.mapAttrsToList (template: paths:
        lib.concatMapStrings (path: ''
          place "$dir/${template}" "$HOME/${path}"
        '')
        paths)
      targets)}
      osc=$(sh "$dir/osc.sh")
      for tty in /dev/pts/[0-9]*; do
        if [ -O "$tty" ] && [ -w "$tty" ]; then
          printf '%s' "$osc" 2>/dev/null >"$tty" || :
        fi
      done

      dconf write /org/gnome/desktop/interface/color-scheme "'prefer-$1'"
      dconf write /org/gnome/desktop/interface/gtk-theme "'$gtk'"
    '';
  };
in {
  options.user.theme.apply = lib.mkOption {
    type = lib.types.functionTo lib.types.str;
    readOnly = true;
    default = name:
      if schemes ? ${name}
      then "${lib.getExe theme} ${name}"
      else throw "theme: no colour scheme named ${name} in colorschemes.data.nix; there is light and dark";
    description = "The shell command that applies the light or dark colour scheme from colorschemes.data.nix to every themed program at once, and sets the desktop colour-scheme and GTK theme that portal-aware and GTK3 apps follow live.";
  };

  config.environment.systemPackages = [theme pkgs.dconf adwaitaDark];
}
