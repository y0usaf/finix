{
  config,
  flakeInputs,
  lib,
  pkgs,
  ...
}: let
  wallustPkg = pkgs.wallust;
  wallustCfg = config.user.appearance.wallust;
  zjstatusEnabled = lib.attrByPath ["user" "shell" "zellij" "zjstatus" "enable"] false config;
  zjstatusHintsWasm = "${flakeInputs.zjstatus-hints.packages."${pkgs.stdenv.hostPlatform.system}".default}/bin/zjstatus-hints.wasm";
  niriEnabled = lib.attrByPath ["user" "ui" "niri" "enable"] false config;
  vicinaeEnabled = lib.attrByPath ["user" "ui" "vicinae" "enable"] false config;
  cmusEnabled = lib.attrByPath ["user" "programs" "cmus" "enable"] false config;
  vesktopEnabled = lib.attrByPath ["user" "programs" "discord" "vesktop" "enable"] false config;
  gpuishellEnabled = lib.attrByPath ["user" "ui" "gpuishell" "enable"] false config;

  inherit (builtins) toJSON;

  # ═══════════════════════════════════════════════════════════════════
  # Colorschemes
  # ═══════════════════════════════════════════════════════════════════

  colorschemes = {
    black = {
      colors = {
        color0 = "#000000";
        color1 = "#5f8787";
        color2 = "#a5aaa7";
        color3 = "#626b67";
        color4 = "#888888";
        color5 = "#999999";
        color6 = "#aaaaaa";
        color7 = "#c1c1c1";
        color8 = "#333333";
        color9 = "#5f8787";
        color10 = "#a5aaa7";
        color11 = "#626b67";
        color12 = "#888888";
        color13 = "#999999";
        color14 = "#aaaaaa";
        color15 = "#c1c1c1";
      };
      special = {
        background = "#000000";
        foreground = "#c1c1c1";
        cursor = "#5f8787";
      };
    };
    dopamine = {
      colors = {
        color0 = "#000000";
        color1 = "#ff006e";
        color2 = "#00ff88";
        color3 = "#ffbe0b";
        color4 = "#00d9ff";
        color5 = "#c71585";
        color6 = "#00ffb3";
        color7 = "#e0e0ff";
        color8 = "#1a1a2e";
        color9 = "#ff0055";
        color10 = "#00ff99";
        color11 = "#ffcc00";
        color12 = "#00e5ff";
        color13 = "#ff00ff";
        color14 = "#00ffff";
        color15 = "#ffffff";
      };
      special = {
        background = "#000000";
        foreground = "#f0f0ff";
        cursor = "#00ffff";
      };
    };
    eva01 = {
      colors = {
        color0 = "#1a0033";
        color1 = "#c71585";
        color2 = "#00ff00";
        color3 = "#ff00ff";
        color4 = "#0088ff";
        color5 = "#9400d3";
        color6 = "#00ff99";
        color7 = "#e0d5ff";
        color8 = "#2a0052";
        color9 = "#ff0088";
        color10 = "#00ff66";
        color11 = "#ff00ff";
        color12 = "#00ffff";
        color13 = "#c71585";
        color14 = "#00ff33";
        color15 = "#ffffff";
      };
      special = {
        background = "#1a0033";
        foreground = "#e0d5ff";
        cursor = "#00ff00";
      };
    };
    eva02 = {
      colors = {
        color0 = "#1a0000";
        color1 = "#ff0000";
        color2 = "#ff3300";
        color3 = "#ff5500";
        color4 = "#cc0000";
        color5 = "#aa0000";
        color6 = "#ff2200";
        color7 = "#ff7700";
        color8 = "#550000";
        color9 = "#ff1100";
        color10 = "#ff4400";
        color11 = "#ff6600";
        color12 = "#dd0000";
        color13 = "#bb0000";
        color14 = "#ff3300";
        color15 = "#ff8800";
      };
      special = {
        background = "#1a0000";
        foreground = "#ff8800";
        cursor = "#ff0000";
      };
    };
    p3 = {
      colors = {
        color0 = "#001433";
        color1 = "#1464c8";
        color2 = "#f0f0ff";
        color3 = "#00a0ff";
        color4 = "#0090ff";
        color5 = "#0030c0";
        color6 = "#b0d8ff";
        color7 = "#c8dcff";
        color8 = "#001a50";
        color9 = "#0070ff";
        color10 = "#ffffff";
        color11 = "#0098ff";
        color12 = "#00ffff";
        color13 = "#0050c0";
        color14 = "#ffffff";
        color15 = "#ffffff";
      };
      special = {
        background = "#001433";
        foreground = "#c8dcff";
        cursor = "#00ffff";
      };
    };
    p4 = {
      colors = {
        color0 = "#332500";
        color1 = "#c89514";
        color2 = "#fffbf0";
        color3 = "#ffb700";
        color4 = "#ffb700";
        color5 = "#c08a00";
        color6 = "#ffe9b0";
        color7 = "#ffefc8";
        color8 = "#503900";
        color9 = "#ffb700";
        color10 = "#ffffff";
        color11 = "#ffb700";
        color12 = "#ffff00";
        color13 = "#c08a00";
        color14 = "#ffffff";
        color15 = "#ffffff";
      };
      special = {
        background = "#332500";
        foreground = "#ffefc8";
        cursor = "#ffff00";
      };
    };
    p5 = {
      colors = {
        color0 = "#330000";
        color1 = "#c81414";
        color2 = "#fff0f0";
        color3 = "#ff0000";
        color4 = "#ff0000";
        color5 = "#c00000";
        color6 = "#ffb0b0";
        color7 = "#ffc8c8";
        color8 = "#500000";
        color9 = "#ff0000";
        color10 = "#ffffff";
        color11 = "#ff0000";
        color12 = "#ff00ff";
        color13 = "#c00000";
        color14 = "#ffffff";
        color15 = "#ffffff";
      };
      special = {
        background = "#330000";
        foreground = "#ffc8c8";
        cursor = "#ff0000";
      };
    };
  };

  # ═══════════════════════════════════════════════════════════════════
  # Template strings
  # ═══════════════════════════════════════════════════════════════════

  colorsCss = ''
    /* Wallust generated colors - @import this file for dynamic theming */
    :root {
      /* Terminal palette */
      --color0: {{ color0 }};
      --color1: {{ color1 }};
      --color2: {{ color2 }};
      --color3: {{ color3 }};
      --color4: {{ color4 }};
      --color5: {{ color5 }};
      --color6: {{ color6 }};
      --color7: {{ color7 }};
      --color8: {{ color8 }};
      --color9: {{ color9 }};
      --color10: {{ color10 }};
      --color11: {{ color11 }};
      --color12: {{ color12 }};
      --color13: {{ color13 }};
      --color14: {{ color14 }};
      --color15: {{ color15 }};

      /* Special colors */
      --background: {{ background }};
      --foreground: {{ foreground }};
      --cursor: {{ cursor }};

      /* Semantic aliases */
      --bg: {{ background }};
      --fg: {{ foreground }};
      --black: {{ color0 }};
      --red: {{ color1 }};
      --green: {{ color2 }};
      --yellow: {{ color3 }};
      --blue: {{ color4 }};
      --magenta: {{ color5 }};
      --cyan: {{ color6 }};
      --white: {{ color7 }};
      --bright-black: {{ color8 }};
      --bright-red: {{ color9 }};
      --bright-green: {{ color10 }};
      --bright-yellow: {{ color11 }};
      --bright-blue: {{ color12 }};
      --bright-magenta: {{ color13 }};
      --bright-cyan: {{ color14 }};
      --bright-white: {{ color15 }};
    }
  '';

  footColors = ''
    [colors-dark]
    foreground={{foreground | strip}}
    background={{background | strip}}
    selection-foreground={{background | strip}}
    selection-background={{foreground | strip}}
    urls={{color6 | strip}}

    regular0={{color0 | strip}}
    regular1={{color1 | strip}}
    regular2={{color2 | strip}}
    regular3={{color3 | strip}}
    regular4={{color4 | strip}}
    regular5={{color5 | strip}}
    regular6={{color6 | strip}}
    regular7={{color7 | strip}}

    bright0={{color8 | strip}}
    bright1={{color9 | strip}}
    bright2={{color10 | strip}}
    bright3={{color11 | strip}}
    bright4={{color12 | strip}}
    bright5={{color13 | strip}}
    bright6={{color14 | strip}}
    bright7={{color15 | strip}}
  '';

  shellColors = ''
    # ANSI color palette references (256-color mode)
    # These reference the terminal's colors 0-15 which Wallust controls
    # When you run `wallust cs <colorscheme>`, the terminal colors change and these automatically reflect

    WALLUST_COLOR0=$'\033[38;5;0m'
    WALLUST_COLOR1=$'\033[38;5;1m'
    WALLUST_COLOR2=$'\033[38;5;2m'
    WALLUST_COLOR3=$'\033[38;5;3m'
    WALLUST_COLOR4=$'\033[38;5;4m'
    WALLUST_COLOR5=$'\033[38;5;5m'
    WALLUST_COLOR6=$'\033[38;5;6m'
    WALLUST_COLOR7=$'\033[38;5;7m'

    WALLUST_COLOR8=$'\033[38;5;8m'
    WALLUST_COLOR9=$'\033[38;5;9m'
    WALLUST_COLOR10=$'\033[38;5;10m'
    WALLUST_COLOR11=$'\033[38;5;11m'
    WALLUST_COLOR12=$'\033[38;5;12m'
    WALLUST_COLOR13=$'\033[38;5;13m'
    WALLUST_COLOR14=$'\033[38;5;14m'
    WALLUST_COLOR15=$'\033[38;5;15m'

    export WALLUST_COLOR{0..15}
  '';

  pywalColorsJson = ''    {
    "wallpaper": "{{wallpaper}}",
    "alpha": "{{alpha}}",
    "special": {
    "background": "{{background}}",
    "foreground": "{{foreground}}",
    "cursor": "{{cursor}}"
    },
    "colors": {
    "color0": "{{color0}}",
    "color1": "{{color1}}",
    "color2": "{{color2}}",
    "color3": "{{color3}}",
    "color4": "{{color4}}",
    "color5": "{{color5}}",
    "color6": "{{color6}}",
    "color7": "{{color7}}",
    "color8": "{{color8}}",
    "color9": "{{color9}}",
    "color10": "{{color10}}",
    "color11": "{{color11}}",
    "color12": "{{color12}}",
    "color13": "{{color13}}",
    "color14": "{{color14}}",
    "color15": "{{color15}}"
    }
    }'';

  discordColors = ''
    /* Discord color palette from wallust */
    :root {
      --base-red: {{ color1 }} !important;
      --base-green: {{ color2 }} !important;
      --base-blue: {{ color4 }} !important;
      --base-yellow: {{ color3 }} !important;
      --base-purple: {{ color5 }} !important;

      --text-0: {{ foreground }} !important;
      --text-1: {{ color15 }} !important;
      --text-2: {{ color7 }} !important;
      --text-3: {{ color7 }} !important;
      --text-4: {{ color7 }} !important;
      --text-5: {{ cursor }} !important;

      --bg-1: {{ color0 }} !important;
      --bg-2: {{ color0 }} !important;
      --bg-3: {{ color0 }} !important;
      --bg-4: {{ background }} !important;

      --hover: color-mix(in srgb, {{ color8 }} 10%, transparent) !important;
      --active: color-mix(in srgb, {{ color8 }} 20%, transparent) !important;
      --active-2: color-mix(in srgb, {{ color8 }} 30%, transparent) !important;
      --message-hover: var(--hover) !important;

      --red-1: {{ color9 }} !important;
      --red-2: {{ color1 }} !important;
      --red-3: {{ color1 }} !important;
      --red-4: {{ color1 }} !important;
      --red-5: {{ color1 }} !important;

      --green-1: {{ color10 }} !important;
      --green-2: {{ color2 }} !important;
      --green-3: {{ color2 }} !important;
      --green-4: {{ color2 }} !important;
      --green-5: {{ color2 }} !important;

      --blue-1: {{ color12 }} !important;
      --blue-2: {{ color4 }} !important;
      --blue-3: {{ color4 }} !important;
      --blue-4: {{ color4 }} !important;
      --blue-5: {{ color4 }} !important;

      --yellow-1: {{ color11 }} !important;
      --yellow-2: {{ color3 }} !important;
      --yellow-3: {{ color3 }} !important;
      --yellow-4: {{ color3 }} !important;
      --yellow-5: {{ color3 }} !important;

      --purple-1: {{ color13 }} !important;
      --purple-2: {{ color5 }} !important;
      --purple-3: {{ color5 }} !important;
      --purple-4: {{ color5 }} !important;
      --purple-5: {{ color5 }} !important;

      --accent-1: var(--purple-1) !important;
      --accent-2: var(--purple-2) !important;
      --accent-3: var(--purple-3) !important;
      --accent-4: var(--purple-4) !important;
      --accent-5: var(--purple-5) !important;
      --accent-new: var(--red-2) !important;

      --online: var(--green-2) !important;
      --dnd: var(--red-2) !important;
      --idle: var(--yellow-2) !important;
      --streaming: var(--purple-2) !important;
      --offline: var(--text-4) !important;

      --border-light: var(--text-5) !important;
      --border: var(--text-5) !important;
      --border-hover: var(--purple-2) !important;
      --button-border: color-mix(in srgb, {{ foreground }} 10%, transparent) !important;

      --mention: linear-gradient(to right, color-mix(in srgb, var(--accent-2) 10%, transparent) 40%, transparent) !important;
      --mention-hover: linear-gradient(to right, color-mix(in srgb, var(--accent-2) 5%, transparent) 40%, transparent) !important;
      --reply: linear-gradient(to right, color-mix(in srgb, var(--text-3) 10%, transparent) 40%, transparent) !important;
      --reply-hover: linear-gradient(to right, color-mix(in srgb, var(--text-3) 5%, transparent) 40%, transparent) !important;
    }

    /* Discord CSS variable mappings */
    body,
    .theme-dark:not(.custom-user-profile-theme),
    .theme-light:not(.custom-user-profile-theme) {
      --activity-card-background: var(--bg-3) !important;
      --background-accent: var(--bg-2) !important;
      --background-floating: var(--bg-3) !important;
      --background-nested-floating: var(--bg-4) !important;
      --background-mentioned: var(--mention) !important;
      --background-mentioned-hover: var(--mention-hover) !important;
      --background-message-highlight: var(--reply) !important;
      --background-message-highlight-hover: var(--reply-hover) !important;
      --background-message-hover: var(--message-hover) !important;
      --background-primary: var(--bg-4) !important;
      --background-secondary: var(--bg-3) !important;
      --background-secondary-alt: var(--bg-3) !important;
      --background-tertiary: var(--bg-4) !important;
      --bg-base-primary: var(--bg-4) !important;
      --bg-base-secondary: var(--bg-4) !important;
      --bg-base-tertiary: var(--bg-3) !important;
      --background-base-low: var(--bg-4) !important;
      --background-base-lower: var(--bg-4) !important;
      --background-base-lowest: var(--bg-4) !important;
      --background-mod-subtle: var(--hover) !important;
      --background-mod-normal: var(--active) !important;
      --background-mod-strong: var(--active-2) !important;
      --background-modifier-accent: var(--hover) !important;
      --background-modifier-active: var(--active) !important;
      --background-modifier-hover: var(--hover) !important;
      --background-modifier-selected: var(--active) !important;
      --background-surface-high: var(--bg-3) !important;
      --background-surface-higher: var(--bg-3) !important;
      --background-surface-highest: var(--bg-3) !important;
      --bg-surface-overlay: var(--bg-4) !important;
      --bg-surface-raised: var(--bg-3) !important;
      --text-brand: var(--accent-1) !important;
      --text-danger: var(--red-1) !important;
      --text-link: var(--accent-1) !important;
      --text-low-contrast: var(--text-4) !important;
      --text-muted: var(--text-5) !important;
      --text-muted-on-default: var(--text-4) !important;
      --text-normal: var(--text-3) !important;
      --text-positive: var(--green-1) !important;
      --text-primary: var(--text-3) !important;
      --text-secondary: var(--text-4) !important;
      --text-tertiary: var(--text-4) !important;
      --text-warning: var(--yellow-1) !important;
      --text-default: var(--text-3) !important;
      --border-faint: var(--border-light) !important;
      --border-subtle: var(--border) !important;
      --border-normal: var(--border) !important;
      --border-strong: var(--border) !important;
      --input-border: var(--border) !important;
      --status-danger: var(--red-2) !important;
      --status-dnd: var(--dnd) !important;
      --status-idle: var(--idle) !important;
      --status-offline: var(--offline) !important;
      --status-online: var(--online) !important;
      --status-positive: var(--green-2) !important;
      --status-speaking: var(--green-2) !important;
      --status-warning: var(--yellow-2) !important;
      --interactive-normal: var(--text-4) !important;
      --interactive-hover: var(--text-3) !important;
      --interactive-active: var(--text-3) !important;
      --interactive-muted: var(--text-5) !important;
      --bg-brand: var(--accent-2) !important;
      --brand-360: var(--accent-2) !important;
      --brand-500: var(--accent-2) !important;
      --blurple-50: var(--accent-2) !important;
      --mention-foreground: var(--accent-1) !important;
      --mention-background: color-mix(in hsl, var(--accent-2), transparent 90%) !important;
      --input-background: var(--bg-3) !important;
      --channel-text-area-placeholder: var(--text-5) !important;
      --deprecated-text-input-bg: var(--bg-3) !important;
      --deprecated-text-input-border: var(--border-light) !important;
      --modal-background: var(--bg-4) !important;
      --modal-footer-background: var(--bg-4) !important;
      --scrollbar-auto-thumb: var(--bg-3) !important;
      --scrollbar-auto-track: transparent !important;
      --scrollbar-thin-thumb: var(--bg-3) !important;
      --scrollbar-thin-track: transparent !important;
      --chat-background-default: var(--bg-3) !important;
      --chat-text-muted: var(--text-5) !important;
      --white: var(--text-0) !important;
      --white-500: var(--text-0) !important;
      --background-code: var(--bg-3) !important;
      --card-primary-bg: var(--bg-3) !important;
      --card-secondary-bg: var(--bg-2) !important;
    }
  '';

  niriBorders = ''
    layout {
      border {
        on
        active-color "{{ cursor }}"
        inactive-color "{{ color8 }}"
      }
      tab-indicator {
        active-color "{{ cursor }}"
        inactive-color "{{ color8 }}"
      }
    }
  '';

  vicinaeColors = ''
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

  cmusColors = ''
    # Base colors
    set color_win_fg=default
    set color_win_bg=default
    set color_win_dir=default

    # Window styling - accent (color5/magenta)
    set color_win_cur=5
    set color_win_cur_sel_fg=15
    set color_win_cur_sel_bg=5
    set color_separator=darkgray

    # Command line
    set color_cmdline_bg=default
    set color_cmdline_fg=default

    # Status and title bars - accent color (color5/magenta)
    set color_statusline_fg=white
    set color_statusline_bg=5
    set color_statusline_progress_bg=5
    set color_statusline_progress_fg=white
    set color_win_title_fg=white
    set color_win_title_bg=5

    # Error messages
    set color_error=1
    set color_info=2
  '';

  gtkColors = ''
    /* Wallust generated GTK colors */

    /* Terminal palette */
    @define-color color0 {{ color0 }};
    @define-color color1 {{ color1 }};
    @define-color color2 {{ color2 }};
    @define-color color3 {{ color3 }};
    @define-color color4 {{ color4 }};
    @define-color color5 {{ color5 }};
    @define-color color6 {{ color6 }};
    @define-color color7 {{ color7 }};
    @define-color color8 {{ color8 }};
    @define-color color9 {{ color9 }};
    @define-color color10 {{ color10 }};
    @define-color color11 {{ color11 }};
    @define-color color12 {{ color12 }};
    @define-color color13 {{ color13 }};
    @define-color color14 {{ color14 }};
    @define-color color15 {{ color15 }};

    /* Special colors */
    @define-color background {{ background }};
    @define-color foreground {{ foreground }};
    @define-color cursor {{ cursor }};
    @define-color accent {{ cursor }};

    /* Semantic aliases */
    @define-color bg {{ background }};
    @define-color fg {{ foreground }};
    @define-color black {{ color0 }};
    @define-color red {{ color1 }};
    @define-color green {{ color2 }};
    @define-color yellow {{ color3 }};
    @define-color blue {{ color4 }};
    @define-color magenta {{ color5 }};
    @define-color cyan {{ color6 }};
    @define-color white {{ color7 }};
    @define-color bright_black {{ color8 }};
    @define-color bright_red {{ color9 }};
    @define-color bright_green {{ color10 }};
    @define-color bright_yellow {{ color11 }};
    @define-color bright_blue {{ color12 }};
    @define-color bright_magenta {{ color13 }};
    @define-color bright_cyan {{ color14 }};
    @define-color bright_white {{ color15 }};
  '';

  obsidianColors = ''
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

  gpuishellTheme = ''
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

  rudoTheme = ''
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

  rudoOsc = ''
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

  # ═══════════════════════════════════════════════════════════════════
  # Wallust config template (function with conditional sections)
  # ═══════════════════════════════════════════════════════════════════

  mkWallustConfig = {
    cmusEnabled ? false,
    extraTemplates ? "",
    gpuishellEnabled ? false,
    niriEnabled ? false,
    vestopkEnabled ? false,
    vicinaeEnabled ? false,
  }: ''
    backend = "fastresize"
    color_space = "lch"
    palette = "dark"
    check_contrast = true

    [templates]
    # Web CSS variables - for browsers, Electron apps, etc.
    colors-css = { template = "colors.css", target = "~/.cache/wallust/colors.css" }

    # GTK CSS colors - for AGS and other GTK apps
    gtk-colors = { template = "gtk-colors.css", target = "~/.cache/wallust/gtk-colors.css" }

    # Shell variables (hex colors for cat-fetch and other shell apps)
    shell-colors = { template = "shell-colors.sh", target = "~/.cache/wallust/shell-colors.sh" }

    # Pywal-compatible colors.json for pywalfox
    pywal-colors = { template = "colors.json", target = "~/.cache/wal/colors.json" }

    # Foot terminal colors (cache-only theming)
    foot-colors = { template = "foot-colors.ini", target = "~/.cache/wallust/colors_foot.ini" }

    # Rudo terminal theme (picked up on next launch)
    rudo-theme = { template = "rudo-theme.toml", target = "~/.cache/wallust/rudo-theme.toml" }

    # Rudo live OSC palette updater (used by wt for hot reload)
    rudo-osc = { template = "rudo-osc.sh", target = "~/.cache/wallust/rudo-osc.sh" }

    # Zellij templates
    zellij-config = { template = "zellij-config.kdl", target = "~/.config/zellij/config.kdl" }
    zellij-layout = { template = "zellij-layout.kdl", target = "~/.config/zellij/layouts/zjstatus.kdl" }

    # Obsidian Shimmering Focus theme colors
    obsidian-colors = { template = "obsidian-colors.css", target = "~/Documents/obsidian/.obsidian/snippets/wallust-colours.css" }

    # Discord theme colors (hot-reloadable via Vencord)
    discord-colors = { template = "discord-colors.css", target = "~/.config/Vencord/themes/wallust-colors.css" }
    ${lib.optionalString vestopkEnabled ''
      # Vesktop theme colors (same as Discord, just different location)
      vesktop-colors = { template = "discord-colors.css", target = "~/.config/vesktop/themes/wallust-colors.css" }
    ''}${lib.optionalString niriEnabled ''
      # Niri border colors (included via niri's include directive)
      niri-borders = { template = "niri-borders.kdl", target = "~/.cache/wallust/niri-borders.kdl" }
    ''}${lib.optionalString vicinaeEnabled ''
      # Vicinae theme (auto-generated from wallust colors)
      vicinae-colors = { template = "vicinae-colors.toml", target = "~/.local/share/vicinae/themes/wallust-auto.toml" }
    ''}${lib.optionalString cmusEnabled ''
      # cmus colorscheme (uses fixed ANSI indices, palette varies per wallust theme)
      cmus-colors = { template = "cmus-colors.theme", target = "~/.config/cmus/wallust-auto.theme" }
    ''}${lib.optionalString gpuishellEnabled ''
      # gpui-shell theme colors
      gpuishell-theme = { template = "gpuishell-theme.toml", target = "~/.config/gpuishell/theme.toml" }
    ''}${extraTemplates}
  '';

  # ═══════════════════════════════════════════════════════════════════
  # Zellij templates
  # ═══════════════════════════════════════════════════════════════════

  zellijTheme = ''
    themes {
      wallust {
        text_unselected {
          base {{ color7 | red }} {{ color7 | green }} {{ color7 | blue }}
          background {{ background | red }} {{ background | green }} {{ background | blue }}
          emphasis_0 {{ color1 | red }} {{ color1 | green }} {{ color1 | blue }}
          emphasis_1 {{ color3 | red }} {{ color3 | green }} {{ color3 | blue }}
          emphasis_2 {{ color5 | red }} {{ color5 | green }} {{ color5 | blue }}
          emphasis_3 {{ color4 | red }} {{ color4 | green }} {{ color4 | blue }}
        }
        text_selected {
          base {{ color15 | red }} {{ color15 | green }} {{ color15 | blue }}
          background {{ color8 | red }} {{ color8 | green }} {{ color8 | blue }}
          emphasis_0 {{ color9 | red }} {{ color9 | green }} {{ color9 | blue }}
          emphasis_1 {{ color11 | red }} {{ color11 | green }} {{ color11 | blue }}
          emphasis_2 {{ color13 | red }} {{ color13 | green }} {{ color13 | blue }}
          emphasis_3 {{ color12 | red }} {{ color12 | green }} {{ color12 | blue }}
        }
        ribbon_unselected {
          base {{ color0 | red }} {{ color0 | green }} {{ color0 | blue }}
          background {{ color4 | red }} {{ color4 | green }} {{ color4 | blue }}
          emphasis_0 {{ color1 | red }} {{ color1 | green }} {{ color1 | blue }}
          emphasis_1 {{ color5 | red }} {{ color5 | green }} {{ color5 | blue }}
          emphasis_2 {{ color3 | red }} {{ color3 | green }} {{ color3 | blue }}
          emphasis_3 {{ color6 | red }} {{ color6 | green }} {{ color6 | blue }}
        }
        ribbon_selected {
          base {{ color9 | red }} {{ color9 | green }} {{ color9 | blue }}
          background {{ color8 | red }} {{ color8 | green }} {{ color8 | blue }}
          emphasis_0 {{ color11 | red }} {{ color11 | green }} {{ color11 | blue }}
          emphasis_1 {{ color13 | red }} {{ color13 | green }} {{ color13 | blue }}
          emphasis_2 {{ color12 | red }} {{ color12 | green }} {{ color12 | blue }}
          emphasis_3 {{ color14 | red }} {{ color14 | green }} {{ color14 | blue }}
        }
        table_title {
          base {{ color3 | red }} {{ color3 | green }} {{ color3 | blue }}
          background {{ background | red }} {{ background | green }} {{ background | blue }}
          emphasis_0 {{ color1 | red }} {{ color1 | green }} {{ color1 | blue }}
          emphasis_1 {{ color5 | red }} {{ color5 | green }} {{ color5 | blue }}
          emphasis_2 {{ color6 | red }} {{ color6 | green }} {{ color6 | blue }}
          emphasis_3 {{ color4 | red }} {{ color4 | green }} {{ color4 | blue }}
        }
        table_cell_unselected {
          base {{ color7 | red }} {{ color7 | green }} {{ color7 | blue }}
          background {{ background | red }} {{ background | green }} {{ background | blue }}
          emphasis_0 {{ color1 | red }} {{ color1 | green }} {{ color1 | blue }}
          emphasis_1 {{ color3 | red }} {{ color3 | green }} {{ color3 | blue }}
          emphasis_2 {{ color5 | red }} {{ color5 | green }} {{ color5 | blue }}
          emphasis_3 {{ color6 | red }} {{ color6 | green }} {{ color6 | blue }}
        }
        table_cell_selected {
          base {{ color15 | red }} {{ color15 | green }} {{ color15 | blue }}
          background {{ color8 | red }} {{ color8 | green }} {{ color8 | blue }}
          emphasis_0 {{ color9 | red }} {{ color9 | green }} {{ color9 | blue }}
          emphasis_1 {{ color11 | red }} {{ color11 | green }} {{ color11 | blue }}
          emphasis_2 {{ color13 | red }} {{ color13 | green }} {{ color13 | blue }}
          emphasis_3 {{ color12 | red }} {{ color12 | green }} {{ color12 | blue }}
        }
        list_unselected {
          base {{ color7 | red }} {{ color7 | green }} {{ color7 | blue }}
          background {{ color8 | red }} {{ color8 | green }} {{ color8 | blue }}
          emphasis_0 {{ color1 | red }} {{ color1 | green }} {{ color1 | blue }}
          emphasis_1 {{ color3 | red }} {{ color3 | green }} {{ color3 | blue }}
          emphasis_2 {{ color5 | red }} {{ color5 | green }} {{ color5 | blue }}
          emphasis_3 {{ color4 | red }} {{ color4 | green }} {{ color4 | blue }}
        }
        list_selected {
          base {{ color15 | red }} {{ color15 | green }} {{ color15 | blue }}
          background {{ color8 | red }} {{ color8 | green }} {{ color8 | blue }}
          emphasis_0 {{ color9 | red }} {{ color9 | green }} {{ color9 | blue }}
          emphasis_1 {{ color11 | red }} {{ color11 | green }} {{ color11 | blue }}
          emphasis_2 {{ color13 | red }} {{ color13 | green }} {{ color13 | blue }}
          emphasis_3 {{ color12 | red }} {{ color12 | green }} {{ color12 | blue }}
        }
        frame_selected {
          base {{ cursor | red }} {{ cursor | green }} {{ cursor | blue }}
          background {{ background | red }} {{ background | green }} {{ background | blue }}
          emphasis_0 {{ color1 | red }} {{ color1 | green }} {{ color1 | blue }}
          emphasis_1 {{ color3 | red }} {{ color3 | green }} {{ color3 | blue }}
          emphasis_2 {{ color5 | red }} {{ color5 | green }} {{ color5 | blue }}
          emphasis_3 {{ color6 | red }} {{ color6 | green }} {{ color6 | blue }}
        }
        frame_highlight {
          base {{ color9 | red }} {{ color9 | green }} {{ color9 | blue }}
          background {{ background | red }} {{ background | green }} {{ background | blue }}
          emphasis_0 {{ color1 | red }} {{ color1 | green }} {{ color1 | blue }}
          emphasis_1 {{ color5 | red }} {{ color5 | green }} {{ color5 | blue }}
          emphasis_2 {{ color3 | red }} {{ color3 | green }} {{ color3 | blue }}
          emphasis_3 {{ color6 | red }} {{ color6 | green }} {{ color6 | blue }}
        }
        frame_unselected {
          base {{ color7 | red }} {{ color7 | green }} {{ color7 | blue }}
          background {{ background | red }} {{ background | green }} {{ background | blue }}
          emphasis_0 {{ color8 | red }} {{ color8 | green }} {{ color8 | blue }}
          emphasis_1 {{ color1 | red }} {{ color1 | green }} {{ color1 | blue }}
          emphasis_2 {{ color5 | red }} {{ color5 | green }} {{ color5 | blue }}
          emphasis_3 {{ color4 | red }} {{ color4 | green }} {{ color4 | blue }}
        }
        exit_code_success {
          base {{ color2 | red }} {{ color2 | green }} {{ color2 | blue }}
          background {{ background | red }} {{ background | green }} {{ background | blue }}
          emphasis_0 {{ color10 | red }} {{ color10 | green }} {{ color10 | blue }}
          emphasis_1 {{ color3 | red }} {{ color3 | green }} {{ color3 | blue }}
          emphasis_2 {{ color6 | red }} {{ color6 | green }} {{ color6 | blue }}
          emphasis_3 {{ color4 | red }} {{ color4 | green }} {{ color4 | blue }}
        }
        exit_code_error {
          base {{ color1 | red }} {{ color1 | green }} {{ color1 | blue }}
          background {{ background | red }} {{ background | green }} {{ background | blue }}
          emphasis_0 {{ color9 | red }} {{ color9 | green }} {{ color9 | blue }}
          emphasis_1 {{ color7 | red }} {{ color7 | green }} {{ color7 | blue }}
          emphasis_2 {{ color8 | red }} {{ color8 | green }} {{ color8 | blue }}
          emphasis_3 {{ color0 | red }} {{ color0 | green }} {{ color0 | blue }}
        }
      }
    }
    ui {
      pane_frames {
        rounded_corners false
        hide_session_name false
      }
    }
    theme "wallust"
  '';

  mkZellijConfigTemplate = {zjstatusEnabled ? false}: ''
    hide_session_name false
    copy_on_select true
    show_startup_tips false
    on_force_close "quit"
    session_serialization false
    pane_frames true
    ${lib.optionalString zjstatusEnabled ''default_layout "zjstatus"''}

    // Using default keybindings for now

    ${lib.optionalString zjstatusEnabled ''
      plugins {
        zjstatus-hints location="file:~/.config/zellij/plugins/zjstatus-hints.wasm" {
          max_length 0
          pipe_name "zjstatus_hints"
          modifier_style "long"
          transparent_bg true
          shared_mode_modifier true
          label_fg "#{{foreground | strip}}"
          hint_prefix " "
          key_prefix "["
          key_suffix "]"
          label_prefix " "
          label_suffix ""
          separator ""

          pane_key_fg    "#{{color10 | strip}}"
          tab_key_fg     "#{{color11 | strip}}"
          resize_key_fg  "#{{color11 | strip}}"
          move_key_fg    "#{{color11 | strip}}"
          scroll_key_fg  "#{{color13 | strip}}"
          search_key_fg  "#{{color13 | strip}}"
          session_key_fg "#{{color13 | strip}}"
          quit_key_fg    "#{{color1 | strip}}"

          new_key_fg         "#{{color10 | strip}}"
          close_key_fg       "#{{color1 | strip}}"
          fullscreen_key_fg  "#{{color14 | strip}}"
          float_key_fg       "#{{color14 | strip}}"
          embed_key_fg       "#{{color14 | strip}}"
          split_right_key_fg "#{{color10 | strip}}"
          split_down_key_fg  "#{{color10 | strip}}"
          rename_key_fg      "#{{color11 | strip}}"
          select_key_fg      "#{{color4 | strip}}"
          increase_key_fg    "#{{color10 | strip}}"
          decrease_key_fg    "#{{color1 | strip}}"
          page_key_fg        "#{{color13 | strip}}"
          half_page_key_fg   "#{{color13 | strip}}"
          edit_key_fg        "#{{color11 | strip}}"
          down_key_fg        "#{{color14 | strip}}"
          up_key_fg          "#{{color14 | strip}}"
          detach_key_fg      "#{{color1 | strip}}"
          manager_key_fg     "#{{color14 | strip}}"
          config_key_fg      "#{{color11 | strip}}"
          plugins_key_fg     "#{{color10 | strip}}"
          about_key_fg       "#{{color4 | strip}}"

          alias_fullscreen  "full"
          alias_split_right "S→"
          alias_split_down  "S↓"
          alias_rename      "ren"
          alias_half_page   "½pg"
          alias_select      "sel"
          alias_break_pane  "break"
          alias_manager     "mgr"
        }
      }

      load_plugins {
        zjstatus-hints
      }
    ''}

    ${zellijTheme}
  '';

  zjstatusLayout = ''
    layout {
      default_tab_template {
        pane size=1 borderless=true {
          plugin location="https://github.com/dj95/zjstatus/releases/download/v0.21.1/zjstatus.wasm" {
            format_left   ""
            format_center "{session}  {mode}  {tabs}  {datetime}"
            format_right  ""
            format_space  " "

            session "#[fg=#{{foreground | strip}}]{name}"
            format_hide_on_overlength "true"
            format_precedence "lrc"

            border_enabled  "false"
            hide_frame_for_single_pane "false"

            mode_normal        "#[fg=bright_cyan,bold]NORMAL"
            mode_locked        "#[fg=red,bold]LOCKED"
            mode_resize        "#[fg=yellow,bold]RESIZE"
            mode_pane          "#[fg=green,bold]PANE"
            mode_tab           "#[fg=yellow,bold]TAB"
            mode_scroll        "#[fg=magenta,bold]SCROLL"
            mode_enter_search  "#[fg=magenta,bold]SEARCH"
            mode_search        "#[fg=magenta,bold]SEARCH"
            mode_rename_tab    "#[fg=yellow,bold]RENAME"
            mode_rename_pane   "#[fg=green,bold]RENAME"
            mode_session       "#[fg=magenta,bold]SESSION"
            mode_move          "#[fg=yellow,bold]MOVE"
            mode_prompt        "#[fg=magenta,bold]PROMPT"
            mode_tmux          "#[fg=red,bold]TMUX"

            tab_normal              "#[fg=#{{foreground | strip}}][{name}] "
            tab_normal_fullscreen   "#[fg=#{{foreground | strip}}][{name} []] "
            tab_normal_sync         "#[fg=#{{foreground | strip}}][{name} <>] "
            tab_active              "#[fg=bright_cyan,bold,underline][{name}] "
            tab_active_fullscreen   "#[fg=bright_cyan,bold,underline][{name} []] "
            tab_active_sync         "#[fg=bright_cyan,bold,underline][{name} <>] "
            tab_floating_indicator  ""

            datetime          "#[fg=#{{foreground | strip}}]{format}"
            datetime_format   "%H:%M:%S"
          }
        }
        children
        pane size=1 borderless=true {
          plugin location="https://github.com/dj95/zjstatus/releases/download/v0.21.1/zjstatus.wasm" {
            format_left   ""
            format_center "{pipe_zjstatus_hints}"
            format_right  ""
            format_space  " "

            border_enabled  "false"
            hide_frame_for_single_pane "false"

            pipe_zjstatus_hints_format "{output}"
            pipe_zjstatus_hints_rendermode "static"
          }
        }
      }
    }
  '';

  # ═══════════════════════════════════════════════════════════════════
  # Library functions
  # ═══════════════════════════════════════════════════════════════════

  mkFiles = {
    cmusEnabled ? false,
    gpuishellEnabled ? false,
    niriEnabled ? false,
    vestopkEnabled ? false,
    vicinaeEnabled ? false,
    zjstatusEnabled ? false,
  }: {
    # Main config
    ".config/wallust/wallust.toml" = mkWallustConfig {
      inherit niriEnabled vicinaeEnabled cmusEnabled vestopkEnabled gpuishellEnabled;
    };

    # Colorschemes
    ".config/wallust/colorschemes/black.json" = toJSON colorschemes.black;
    ".config/wallust/colorschemes/dopamine.json" = toJSON colorschemes.dopamine;
    ".config/wallust/colorschemes/eva01.json" = toJSON colorschemes.eva01;
    ".config/wallust/colorschemes/eva02.json" = toJSON colorschemes.eva02;
    ".config/wallust/colorschemes/p3.json" = toJSON colorschemes.p3;
    ".config/wallust/colorschemes/p4.json" = toJSON colorschemes.p4;
    ".config/wallust/colorschemes/p5.json" = toJSON colorschemes.p5;

    # Shared CSS variables template
    ".config/wallust/templates/colors.css" = colorsCss;

    # Pywal-compatible colors.json for pywalfox
    ".config/wallust/templates/colors.json" = pywalColorsJson;

    # Foot terminal colors
    ".config/wallust/templates/foot-colors.ini" = footColors;

    # Shell colors (hex variables for runtime ANSI conversion)
    ".config/wallust/templates/shell-colors.sh" = shellColors;

    # Zellij templates
    ".config/wallust/templates/zellij-config.kdl" = mkZellijConfigTemplate {inherit zjstatusEnabled;};
    ".config/wallust/templates/zellij-layout.kdl" = zjstatusLayout;

    # Discord theme colors template (wallust will process and output to Vencord and optionally Vesktop)
    ".config/wallust/templates/discord-colors.css" = discordColors;

    # Niri border colors template
    ".config/wallust/templates/niri-borders.kdl" = niriBorders;

    # Vicinae theme template
    ".config/wallust/templates/vicinae-colors.toml" = vicinaeColors;

    # cmus colorscheme template
    ".config/wallust/templates/cmus-colors.theme" = cmusColors;

    # GTK CSS color definitions
    ".config/wallust/templates/gtk-colors.css" = gtkColors;

    # Obsidian Shimmering Focus theme colors
    ".config/wallust/templates/obsidian-colors.css" = obsidianColors;

    # gpui-shell theme template
    ".config/wallust/templates/gpuishell-theme.toml" = gpuishellTheme;

    # Rudo terminal theme template
    ".config/wallust/templates/rudo-theme.toml" = rudoTheme;

    # Rudo live OSC palette update script
    ".config/wallust/templates/rudo-osc.sh" = rudoOsc;
  };

  mkWtScriptText = {
    browserBinary ? "librewolf",
    vicinaeEnabled ? false,
  }: ''
    if [ -z "''${1:-}" ]; then
      echo "Usage: wt <command> [args...]"
      echo "Commands: cs <colorscheme>, theme <name>, run <image>"
      exit 1
    fi

    # Pass all args to wallust
    wallust "$@"

    # Brief delay for file write (avoid race conditions)
    sleep 0.5

    # Push live palette updates to the current terminal when supported
    if [ -t 1 ] && [ -f "$HOME/.cache/wallust/rudo-osc.sh" ]; then
      sh "$HOME/.cache/wallust/rudo-osc.sh"
    fi

    # Update pywalfox
    pywalfox --browser ${browserBinary} update
    ${lib.optionalString vicinaeEnabled ''

      # Hot-reload vicinae theme
      vicinae theme set wallust-auto 2>/dev/null || true
    ''}'';

  mkStartupScript = {
    defaultTheme,
    wallustBin,
  }: ''
    # Ensure output directories exist (wallust templates write here)
    mkdir -p ~/.config/zellij/layouts
    mkdir -p ~/.cache/wal
    mkdir -p ~/.cache/wallust
    mkdir -p ~/.config/Vencord/settings
    mkdir -p ~/.config/vesktop/settings
    mkdir -p ~/.config/ags
    mkdir -p ~/.local/share/vicinae/themes

    ${wallustBin} ${
      if builtins.hasAttr defaultTheme colorschemes
      then "cs ~/.config/wallust/colorschemes/${defaultTheme}.json"
      else "theme ${defaultTheme}"
    }
  '';
in {
  options.user.appearance.wallust = {
    defaultTheme = lib.mkOption {
      type = lib.types.str;
      default = "dopamine";
      description = "Default theme to apply on login.";
    };
  };

  config = {
    environment.systemPackages = [
      wallustPkg
      (pkgs.writeShellApplication {
        name = "wt";
        runtimeInputs = [wallustPkg pkgs.pywalfox-native];
        text = mkWtScriptText {
          browserBinary = "librewolf";
          inherit vicinaeEnabled;
        };
      })
    ];

    systemd.user.services.wallust-default = {
      description = "Apply default wallust theme";
      wantedBy = ["graphical-session-pre.target"];
      before = ["graphical-session.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "wallust-default" (mkStartupScript {
          wallustBin = "${wallustPkg}/bin/wallust";
          inherit (wallustCfg) defaultTheme;
        });
        RemainAfterExit = true;
      };
    };

    bayt.users."${config.user.name}" =
      {
        files = lib.mapAttrs (_: content: {text = content;}) (mkFiles {
          inherit zjstatusEnabled niriEnabled vicinaeEnabled cmusEnabled gpuishellEnabled;
          vestopkEnabled = vesktopEnabled;
        });
      }
      // lib.optionalAttrs zjstatusEnabled {
        xdg.config.files."zellij/plugins/zjstatus-hints.wasm".source = zjstatusHintsWasm;
      };
  };
}
