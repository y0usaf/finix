{
  config,
  lib,
  ...
}: {
  config.user.appearance.wallust = {
    targets = lib.optionalAttrs (lib.attrByPath ["user" "ui" "gpuishell" "enable"] false config) {
      "gpuishell-theme" = {
        template = "gpuishell-theme.toml";
        target = "~/.config/gpuishell/theme.toml";
      };
    };

    templates."gpuishell-theme.toml" = ''
      font_size_base = 13.0

      [bg]
      primary = "{{ background }}"
      secondary = "{{ color0 }}"
      tertiary = "{{ color8 }}"
      elevated = "{{ color8 }}"

      [text]
      primary = "{{ foreground }}"
      secondary = "{{ color7 }}"
      muted = "{{ color8 }}"
      disabled = "{{ color8 }}"
      placeholder = "{{ color8 }}"

      [border]
      default = "{{ color8 }}"
      subtle = "{{ color0 }}"
      focused = "{{ cursor }}"

      [accent]
      primary = "{{ cursor }}"
      selection = "{{ color4 }}"
      hover = "{{ color12 }}"

      [status]
      success = "{{ color2 }}"
      warning = "{{ color3 }}"
      error = "{{ color1 }}"
      info = "{{ color4 }}"

      [interactive]
      default = "{{ color0 }}"
      hover = "{{ color8 }}"
      active = "{{ color8 }}"
      toggle_on = "{{ cursor }}"
      toggle_on_hover = "{{ color12 }}"
    '';
  };
}
