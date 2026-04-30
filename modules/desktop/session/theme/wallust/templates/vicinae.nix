{
  config,
  lib,
  ...
}: let
  enabled = lib.attrByPath ["user" "ui" "vicinae" "enable"] false config;
in {
  config.user.appearance.wallust = {
    targets = lib.optionalAttrs enabled {
      "vicinae-colors" = {
        template = "vicinae-colors.toml";
        target = "~/.local/share/vicinae/themes/wallust-auto.toml";
      };
    };

    templates."vicinae-colors.toml" = ''
      [meta]
      name = "Wallust Auto"
      description = "Auto-generated theme from Wallust colors"
      variant = "dark"
      inherits = "vicinae-dark"

      [colors.core]
      # Use wallust colors: cursor is accent, color0 is black/background
      accent = "{{ cursor }}"
      background = "{{ color0 }}"
      foreground = "{{ color7 }}"

      [colors.accents.color]
      # Use wallust's ANSI color palette
      red = "{{ color1 }}"
      green = "{{ color2 }}"
      yellow = "{{ color3 }}"
      blue = "{{ color4 }}"
      purple = "{{ color5 }}"
      cyan = "{{ color6 }}"
    '';

    reloadHooks = lib.optionals enabled [
      ''
        # Hot-reload vicinae theme
        vicinae theme set wallust-auto 2>/dev/null || true
      ''
    ];
  };
}
