{...}: {
  config.user.appearance.wallust = {
    targets = {
      "obsidian-colors" = {
        template = "obsidian-colors.css";
        target = "~/Documents/obsidian/.obsidian/snippets/wallust-colours.css";
      };
    };

    templates."obsidian-colors.css" = ''
      .theme-dark.theme-dark {
        --background-primary: {{ background }} !important;
        --background-primary-alt: {{ background }} !important;
        --background-secondary: {{ color8 }} !important;
        --background-secondary-alt: {{ color8 }} !important;
        --background-modifier-form-field: {{ color8 }} !important;

        --titlebar-background: {{ color8 }};
        --titlebar-background-focused: {{ color8 }};

        --color-accent: {{ cursor }} !important;
        --interactive-accent: {{ cursor }} !important;
        --interactive-accent-hover: {{ cursor }} !important;

        --text-normal: {{ foreground }} !important;
        --text-muted: {{ color7 }} !important;

        --alt-heading-color: {{ color5 }};
        --secondary-accent: {{ color3 }};
        --hover-accent: {{ color2 }};
        --link-unresolved-color: {{ color4 }};

        --color-red: {{ color1 }};
        --color-green: {{ color2 }};
        --color-yellow: {{ color3 }};
        --color-blue: {{ color4 }};
        --color-purple: {{ color5 }};
        --color-cyan: {{ color6 }};
        --color-orange: {{ color11 }};
        --color-pink: {{ color13 }};

        --color-red-rgb: {{ color1 | red }}, {{ color1 | green }}, {{ color1 | blue }};
        --color-green-rgb: {{ color2 | red }}, {{ color2 | green }}, {{ color2 | blue }};
        --color-orange-rgb: {{ color11 | red }}, {{ color11 | green }}, {{ color11 | blue }};
      }
    '';
  };
}
