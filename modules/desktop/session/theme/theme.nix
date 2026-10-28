{
  lib,
  pkgs,
  ...
}: let
  schemes = lib.importJSON ./colorschemes.json;

  targets = {
    "discord-colors.css" = [".config/Vencord/themes/palette.css" ".config/vesktop/themes/palette.css"];
    "foot-colors.ini" = [".cache/theme/foot.ini"];
    "gtk-colors.css" = [".cache/theme/gtk.css"];
    "monstar-theme" = [".cache/theme/monstar"];
  };

  render = scheme: text: let
    values = scheme.colors // scheme.special;
    hex = lib.removePrefix "#";
    channel = offset: value: toString (lib.fromHexString (builtins.substring offset 2 (hex value)));
    filters = {
      strip = hex;
      red = channel 0;
      green = channel 2;
      blue = channel 4;
    };
    fill = part:
      if builtins.isString part
      then part
      else let
        filter = builtins.elemAt part 2;
      in
        (
          if filter == null
          then lib.id
          else filters.${filter}
        )
        values.${builtins.elemAt part 0};
  in
    lib.concatMapStrings fill (builtins.split "[{][{] *([a-z0-9]+) *([|] *([a-z]+))? *[}][}]" text);

  themes = pkgs.linkFarm "themes" (lib.concatLists (lib.mapAttrsToList (name: scheme:
    lib.mapAttrsToList (template: _: {
      name = "${name}/${template}";
      path = pkgs.writeText "${name}-${template}" (render scheme (builtins.readFile (./templates + "/${template}")));
    }) (builtins.readDir ./templates))
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
      else throw "theme: no colour scheme named ${name} in colorschemes.json; there is light and dark";
    description = "The shell command that applies the light or dark colour scheme from colorschemes.json to every themed program at once, and sets the desktop colour-scheme and GTK theme that portal-aware and GTK3 apps follow live.";
  };

  config.environment.systemPackages = [theme pkgs.dconf adwaitaDark];
}
