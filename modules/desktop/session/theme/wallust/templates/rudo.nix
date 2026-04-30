_: {
  config.user.appearance.wallust = {
    targets = {
      "rudo-theme" = {
        template = "rudo-theme.toml";
        target = "~/.cache/wallust/rudo-theme.toml";
      };
      "rudo-osc" = {
        template = "rudo-osc.sh";
        target = "~/.cache/wallust/rudo-osc.sh";
      };
    };

    templates."rudo-theme.toml" = ''
      background = "{{ background }}"
      foreground = "{{ foreground }}"
      cursor = "{{ cursor }}"

      color0 = "{{ color0 }}"
      color1 = "{{ color1 }}"
      color2 = "{{ color2 }}"
      color3 = "{{ color3 }}"
      color4 = "{{ color4 }}"
      color5 = "{{ color5 }}"
      color6 = "{{ color6 }}"
      color7 = "{{ color7 }}"
      color8 = "{{ color8 }}"
      color9 = "{{ color9 }}"
      color10 = "{{ color10 }}"
      color11 = "{{ color11 }}"
      color12 = "{{ color12 }}"
      color13 = "{{ color13 }}"
      color14 = "{{ color14 }}"
      color15 = "{{ color15 }}"
    '';

    templates."rudo-osc.sh" = ''
      printf '\033]10;{{ foreground }}\007'
      printf '\033]11;{{ background }}\007'
      printf '\033]12;{{ cursor }}\007'
      printf '\033]4;0;{{ color0 }}\007'
      printf '\033]4;1;{{ color1 }}\007'
      printf '\033]4;2;{{ color2 }}\007'
      printf '\033]4;3;{{ color3 }}\007'
      printf '\033]4;4;{{ color4 }}\007'
      printf '\033]4;5;{{ color5 }}\007'
      printf '\033]4;6;{{ color6 }}\007'
      printf '\033]4;7;{{ color7 }}\007'
      printf '\033]4;8;{{ color8 }}\007'
      printf '\033]4;9;{{ color9 }}\007'
      printf '\033]4;10;{{ color10 }}\007'
      printf '\033]4;11;{{ color11 }}\007'
      printf '\033]4;12;{{ color12 }}\007'
      printf '\033]4;13;{{ color13 }}\007'
      printf '\033]4;14;{{ color14 }}\007'
      printf '\033]4;15;{{ color15 }}\007'
    '';
  };
}
