_: {
  config.user.appearance.wallust = {
    targets = {
      "monstar-colors" = {
        template = "monstar-theme";
        target = "~/.cache/wallust/colors_monstar";
      };
    };

    # Monstar theme file (same syntax as the main config, color keys only).
    # Referenced by the absolute theme path in ~/.config/monstar/config —
    # monstar has no include directive.
    templates."monstar-theme" = ''
      foreground={{foreground | strip}}
      background={{background | strip}}
      cursor-color={{foreground | strip}}
      cursor-text={{background | strip}}
      selection-foreground={{background | strip}}
      selection-background={{foreground | strip}}

      palette=0={{color0 | strip}}
      palette=1={{color1 | strip}}
      palette=2={{color2 | strip}}
      palette=3={{color3 | strip}}
      palette=4={{color4 | strip}}
      palette=5={{color5 | strip}}
      palette=6={{color6 | strip}}
      palette=7={{color7 | strip}}
      palette=8={{color8 | strip}}
      palette=9={{color9 | strip}}
      palette=10={{color10 | strip}}
      palette=11={{color11 | strip}}
      palette=12={{color12 | strip}}
      palette=13={{color13 | strip}}
      palette=14={{color14 | strip}}
      palette=15={{color15 | strip}}
    '';
  };
}
