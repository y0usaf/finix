{
  lib,
  pkgs,
  ...
}: let
  schemes = lib.importJSON ./colorschemes.json;

  targets = {
    "colors.json" = [".cache/wal/colors.json"];
    "discord-colors.css" = [".config/Vencord/themes/palette.css" ".config/vesktop/themes/palette.css"];
    "foot-colors.ini" = [".cache/theme/foot.ini"];
    "gtk-colors.css" = [".cache/theme/gtk.css"];
    "monstar-theme" = [".cache/theme/monstar"];
  };

  render = scheme: text: let
    values =
      scheme.colors
      // scheme.special
      // {
        alpha = "100";
        wallpaper = "";
      };
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

  theme = pkgs.writeShellApplication {
    name = "theme";
    runtimeInputs = [pkgs.coreutils pkgs.pywalfox-native];
    text = ''
      case "''${1:-}" in
        ${lib.concatStringsSep " | " (builtins.attrNames schemes)}) ;;
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

      pywalfox update
    '';
  };
in {
  options.user.theme.apply = lib.mkOption {
    type = lib.types.functionTo lib.types.str;
    readOnly = true;
    default = name:
      if schemes ? ${name}
      then "${lib.getExe theme} ${name}"
      else throw "theme: no colour scheme named ${name} in colorschemes.json";
    description = "The shell command that applies a named colour scheme from colorschemes.json to every themed program at once.";
  };

  config.environment.systemPackages = [theme];
}
