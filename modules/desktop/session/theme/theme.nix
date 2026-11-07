{
  lib,
  pkgs,
  generators,
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

  templates = {
    "discord-colors.css" = generators.sourceFile "discord-colors.css" (generators.cssSource [
      {
        select = ":root";
        set = [
          ["--base-red" "{{ color1 }} !important"]
          ["--base-green" "{{ color2 }} !important"]
          ["--base-blue" "{{ color4 }} !important"]
          ["--base-yellow" "{{ color3 }} !important"]
          ["--base-purple" "{{ color5 }} !important"]
          ["--text-0" "{{ foreground }} !important"]
          ["--text-1" "{{ color15 }} !important"]
          ["--text-2" "{{ color7 }} !important"]
          ["--text-3" "color-mix(in srgb, {{ color7 }} 85%, {{ background }}) !important"]
          ["--text-4" "color-mix(in srgb, {{ color7 }} 60%, {{ background }}) !important"]
          ["--text-5" "color-mix(in srgb, {{ color7 }} 40%, {{ background }}) !important"]
          ["--bg-1" "color-mix(in srgb, {{ color8 }} 20%, {{ background }}) !important"]
          ["--bg-2" "color-mix(in srgb, {{ color8 }} 14%, {{ background }}) !important"]
          ["--bg-3" "color-mix(in srgb, {{ color8 }} 8%, {{ background }}) !important"]
          ["--bg-4" "{{ background }} !important"]
          ["--hover" "color-mix(in srgb, {{ color8 }} 10%, transparent) !important"]
          ["--active" "color-mix(in srgb, {{ color8 }} 20%, transparent) !important"]
          ["--active-2" "color-mix(in srgb, {{ color8 }} 30%, transparent) !important"]
          ["--message-hover" "var(--hover) !important"]
          ["--red-1" "{{ color9 }} !important"]
          ["--red-2" "{{ color1 }} !important"]
          ["--red-3" "{{ color1 }} !important"]
          ["--red-4" "{{ color1 }} !important"]
          ["--red-5" "{{ color1 }} !important"]
          ["--green-1" "{{ color10 }} !important"]
          ["--green-2" "{{ color2 }} !important"]
          ["--green-3" "{{ color2 }} !important"]
          ["--green-4" "{{ color2 }} !important"]
          ["--green-5" "{{ color2 }} !important"]
          ["--blue-1" "{{ color12 }} !important"]
          ["--blue-2" "{{ color4 }} !important"]
          ["--blue-3" "{{ color4 }} !important"]
          ["--blue-4" "{{ color4 }} !important"]
          ["--blue-5" "{{ color4 }} !important"]
          ["--yellow-1" "{{ color11 }} !important"]
          ["--yellow-2" "{{ color3 }} !important"]
          ["--yellow-3" "{{ color3 }} !important"]
          ["--yellow-4" "{{ color3 }} !important"]
          ["--yellow-5" "{{ color3 }} !important"]
          ["--purple-1" "{{ color13 }} !important"]
          ["--purple-2" "{{ color5 }} !important"]
          ["--purple-3" "{{ color5 }} !important"]
          ["--purple-4" "{{ color5 }} !important"]
          ["--purple-5" "{{ color5 }} !important"]
          ["--accent-1" "var(--purple-1) !important"]
          ["--accent-2" "var(--purple-2) !important"]
          ["--accent-3" "var(--purple-3) !important"]
          ["--accent-4" "var(--purple-4) !important"]
          ["--accent-5" "var(--purple-5) !important"]
          ["--accent-new" "var(--red-2) !important"]
          ["--online" "var(--green-2) !important"]
          ["--dnd" "var(--red-2) !important"]
          ["--idle" "var(--yellow-2) !important"]
          ["--streaming" "var(--purple-2) !important"]
          ["--offline" "var(--text-4) !important"]
          ["--border-light" "var(--text-5) !important"]
          ["--border" "var(--text-5) !important"]
          ["--border-hover" "var(--purple-2) !important"]
          ["--button-border" "color-mix(in srgb, {{ foreground }} 10%, transparent) !important"]
          ["--mention" "linear-gradient(to right, color-mix(in srgb, var(--accent-2) 10%, transparent) 40%, transparent) !important"]
          ["--mention-hover" "linear-gradient(to right, color-mix(in srgb, var(--accent-2) 5%, transparent) 40%, transparent) !important"]
          ["--reply" "linear-gradient(to right, color-mix(in srgb, var(--text-3) 10%, transparent) 40%, transparent) !important"]
          ["--reply-hover" "linear-gradient(to right, color-mix(in srgb, var(--text-3) 5%, transparent) 40%, transparent) !important"]
        ];
      }
      {
        select = "body, .theme-dark:not(.custom-user-profile-theme), .theme-light:not(.custom-user-profile-theme)";
        set = [
          ["--activity-card-background" "var(--bg-3) !important"]
          ["--background-accent" "var(--bg-2) !important"]
          ["--background-floating" "var(--bg-3) !important"]
          ["--background-nested-floating" "var(--bg-4) !important"]
          ["--background-mentioned" "var(--mention) !important"]
          ["--background-mentioned-hover" "var(--mention-hover) !important"]
          ["--background-message-highlight" "var(--reply) !important"]
          ["--background-message-highlight-hover" "var(--reply-hover) !important"]
          ["--background-message-hover" "var(--message-hover) !important"]
          ["--background-primary" "var(--bg-4) !important"]
          ["--background-secondary" "var(--bg-3) !important"]
          ["--background-secondary-alt" "var(--bg-3) !important"]
          ["--background-tertiary" "var(--bg-4) !important"]
          ["--bg-base-primary" "var(--bg-4) !important"]
          ["--bg-base-secondary" "var(--bg-4) !important"]
          ["--bg-base-tertiary" "var(--bg-3) !important"]
          ["--background-base-low" "var(--bg-4) !important"]
          ["--background-base-lower" "var(--bg-4) !important"]
          ["--background-base-lowest" "var(--bg-4) !important"]
          ["--background-mod-subtle" "var(--hover) !important"]
          ["--background-mod-normal" "var(--active) !important"]
          ["--background-mod-strong" "var(--active-2) !important"]
          ["--background-modifier-accent" "var(--hover) !important"]
          ["--background-modifier-active" "var(--active) !important"]
          ["--background-modifier-hover" "var(--hover) !important"]
          ["--background-modifier-selected" "var(--active) !important"]
          ["--background-surface-high" "var(--bg-3) !important"]
          ["--background-surface-higher" "var(--bg-3) !important"]
          ["--background-surface-highest" "var(--bg-3) !important"]
          ["--bg-surface-overlay" "var(--bg-4) !important"]
          ["--bg-surface-raised" "var(--bg-3) !important"]
          ["--text-brand" "var(--accent-1) !important"]
          ["--text-danger" "var(--red-1) !important"]
          ["--text-link" "var(--accent-1) !important"]
          ["--text-low-contrast" "var(--text-4) !important"]
          ["--text-muted" "var(--text-5) !important"]
          ["--text-muted-on-default" "var(--text-4) !important"]
          ["--text-normal" "var(--text-3) !important"]
          ["--text-positive" "var(--green-1) !important"]
          ["--text-primary" "var(--text-3) !important"]
          ["--text-secondary" "var(--text-4) !important"]
          ["--text-tertiary" "var(--text-4) !important"]
          ["--text-warning" "var(--yellow-1) !important"]
          ["--text-default" "var(--text-3) !important"]
          ["--border-faint" "var(--border-light) !important"]
          ["--border-subtle" "var(--border) !important"]
          ["--border-normal" "var(--border) !important"]
          ["--border-strong" "var(--border) !important"]
          ["--input-border" "var(--border) !important"]
          ["--status-danger" "var(--red-2) !important"]
          ["--status-dnd" "var(--dnd) !important"]
          ["--status-idle" "var(--idle) !important"]
          ["--status-offline" "var(--offline) !important"]
          ["--status-online" "var(--online) !important"]
          ["--status-positive" "var(--green-2) !important"]
          ["--status-speaking" "var(--green-2) !important"]
          ["--status-warning" "var(--yellow-2) !important"]
          ["--interactive-normal" "var(--text-4) !important"]
          ["--interactive-hover" "var(--text-3) !important"]
          ["--interactive-active" "var(--text-3) !important"]
          ["--interactive-muted" "var(--text-5) !important"]
          ["--bg-brand" "var(--accent-2) !important"]
          ["--brand-360" "var(--accent-2) !important"]
          ["--brand-500" "var(--accent-2) !important"]
          ["--blurple-50" "var(--accent-2) !important"]
          ["--mention-foreground" "var(--accent-1) !important"]
          ["--mention-background" "color-mix(in srgb, var(--accent-2) 10%, transparent) !important"]
          ["--input-background" "var(--bg-3) !important"]
          ["--channel-text-area-placeholder" "var(--text-5) !important"]
          ["--deprecated-text-input-bg" "var(--bg-3) !important"]
          ["--deprecated-text-input-border" "var(--border-light) !important"]
          ["--modal-background" "var(--bg-4) !important"]
          ["--modal-footer-background" "var(--bg-4) !important"]
          ["--scrollbar-auto-thumb" "var(--bg-3) !important"]
          ["--scrollbar-auto-track" "transparent !important"]
          ["--scrollbar-thin-thumb" "var(--bg-3) !important"]
          ["--scrollbar-thin-track" "transparent !important"]
          ["--chat-background-default" "var(--bg-3) !important"]
          ["--chat-text-muted" "var(--text-5) !important"]
          ["--white" "var(--text-0) !important"]
          ["--white-500" "var(--text-0) !important"]
          ["--background-code" "var(--bg-3) !important"]
          ["--card-primary-bg" "var(--bg-3) !important"]
          ["--card-secondary-bg" "var(--bg-2) !important"]
        ];
      }
    ]);
    "foot-colors.ini" = ./templates/foot-colors.ini;
    "gtk-colors.css" = generators.sourceFile "gtk-colors.css" (generators.cssSource [
      {
        at = "@define-color color0 {{ color0 }}";
      }
      {
        at = "@define-color color1 {{ color1 }}";
      }
      {
        at = "@define-color color2 {{ color2 }}";
      }
      {
        at = "@define-color color3 {{ color3 }}";
      }
      {
        at = "@define-color color4 {{ color4 }}";
      }
      {
        at = "@define-color color5 {{ color5 }}";
      }
      {
        at = "@define-color color6 {{ color6 }}";
      }
      {
        at = "@define-color color7 {{ color7 }}";
      }
      {
        at = "@define-color color8 {{ color8 }}";
      }
      {
        at = "@define-color color9 {{ color9 }}";
      }
      {
        at = "@define-color color10 {{ color10 }}";
      }
      {
        at = "@define-color color11 {{ color11 }}";
      }
      {
        at = "@define-color color12 {{ color12 }}";
      }
      {
        at = "@define-color color13 {{ color13 }}";
      }
      {
        at = "@define-color color14 {{ color14 }}";
      }
      {
        at = "@define-color color15 {{ color15 }}";
      }
      {
        at = "@define-color background {{ background }}";
      }
      {
        at = "@define-color foreground {{ foreground }}";
      }
      {
        at = "@define-color cursor {{ cursor }}";
      }
      {
        at = "@define-color accent {{ cursor }}";
      }
      {
        at = "@define-color bg {{ background }}";
      }
      {
        at = "@define-color fg {{ foreground }}";
      }
      {
        at = "@define-color black {{ color0 }}";
      }
      {
        at = "@define-color red {{ color1 }}";
      }
      {
        at = "@define-color green {{ color2 }}";
      }
      {
        at = "@define-color yellow {{ color3 }}";
      }
      {
        at = "@define-color blue {{ color4 }}";
      }
      {
        at = "@define-color magenta {{ color5 }}";
      }
      {
        at = "@define-color cyan {{ color6 }}";
      }
      {
        at = "@define-color white {{ color7 }}";
      }
      {
        at = "@define-color bright_black {{ color8 }}";
      }
      {
        at = "@define-color bright_red {{ color9 }}";
      }
      {
        at = "@define-color bright_green {{ color10 }}";
      }
      {
        at = "@define-color bright_yellow {{ color11 }}";
      }
      {
        at = "@define-color bright_blue {{ color12 }}";
      }
      {
        at = "@define-color bright_magenta {{ color13 }}";
      }
      {
        at = "@define-color bright_cyan {{ color14 }}";
      }
      {
        at = "@define-color bright_white {{ color15 }}";
      }
    ]);
    "monstar-theme" = ./templates/monstar-theme;
    "osc.sh" = generators.sourceFile "osc.sh" (generators.shell.render (({sq, ...}: [
        ["printf" (sq "\\033]10;{{ foreground }}\\007")]
        ["printf" (sq "\\033]11;{{ background }}\\007")]
        ["printf" (sq "\\033]12;{{ cursor }}\\007")]
        ["printf" (sq "\\033]4;0;{{ color0 }}\\007")]
        ["printf" (sq "\\033]4;1;{{ color1 }}\\007")]
        ["printf" (sq "\\033]4;2;{{ color2 }}\\007")]
        ["printf" (sq "\\033]4;3;{{ color3 }}\\007")]
        ["printf" (sq "\\033]4;4;{{ color4 }}\\007")]
        ["printf" (sq "\\033]4;5;{{ color5 }}\\007")]
        ["printf" (sq "\\033]4;6;{{ color6 }}\\007")]
        ["printf" (sq "\\033]4;7;{{ color7 }}\\007")]
        ["printf" (sq "\\033]4;8;{{ color8 }}\\007")]
        ["printf" (sq "\\033]4;9;{{ color9 }}\\007")]
        ["printf" (sq "\\033]4;10;{{ color10 }}\\007")]
        ["printf" (sq "\\033]4;11;{{ color11 }}\\007")]
        ["printf" (sq "\\033]4;12;{{ color12 }}\\007")]
        ["printf" (sq "\\033]4;13;{{ color13 }}\\007")]
        ["printf" (sq "\\033]4;14;{{ color14 }}\\007")]
        ["printf" (sq "\\033]4;15;{{ color15 }}\\007")]
      ])
      generators.shell));
  };

  themes = pkgs.linkFarm "themes" (lib.concatLists (lib.mapAttrsToList (name: scheme:
    lib.mapAttrsToList (template: file: {
      name = "${name}/${template}";
      path = pkgs.writeText "${name}-${template}" (render scheme (builtins.readFile file));
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
      osc=$(${pkgs.runtimeShell} "$dir/osc.sh")
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
