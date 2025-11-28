# Shared wallust templates for NixOS and Darwin
# These use Jinja2 syntax: {{ color0 }}, {{ background | red }}, etc.
{lib}: rec {
  # Shared CSS variables template - importable by any CSS file
  # Output: ~/.config/wallust/colors.css
  colorsCss = ''
    /* Wallust generated colors - @import this file for dynamic theming */
    :root {
      /* Base terminal colors */
      --wallust-color0: {{ color0 }};
      --wallust-color1: {{ color1 }};
      --wallust-color2: {{ color2 }};
      --wallust-color3: {{ color3 }};
      --wallust-color4: {{ color4 }};
      --wallust-color5: {{ color5 }};
      --wallust-color6: {{ color6 }};
      --wallust-color7: {{ color7 }};
      --wallust-color8: {{ color8 }};
      --wallust-color9: {{ color9 }};
      --wallust-color10: {{ color10 }};
      --wallust-color11: {{ color11 }};
      --wallust-color12: {{ color12 }};
      --wallust-color13: {{ color13 }};
      --wallust-color14: {{ color14 }};
      --wallust-color15: {{ color15 }};

      /* Special colors */
      --wallust-background: {{ background }};
      --wallust-foreground: {{ foreground }};
      --wallust-cursor: {{ cursor }};

      /* Semantic aliases */
      --wallust-bg: {{ background }};
      --wallust-fg: {{ foreground }};
      --wallust-black: {{ color0 }};
      --wallust-red: {{ color1 }};
      --wallust-green: {{ color2 }};
      --wallust-yellow: {{ color3 }};
      --wallust-blue: {{ color4 }};
      --wallust-magenta: {{ color5 }};
      --wallust-cyan: {{ color6 }};
      --wallust-white: {{ color7 }};
      --wallust-bright-black: {{ color8 }};
      --wallust-bright-red: {{ color9 }};
      --wallust-bright-green: {{ color10 }};
      --wallust-bright-yellow: {{ color11 }};
      --wallust-bright-blue: {{ color12 }};
      --wallust-bright-magenta: {{ color13 }};
      --wallust-bright-cyan: {{ color14 }};
      --wallust-bright-white: {{ color15 }};
    }
  '';

  # Foot terminal colors (uses | strip to remove # from hex)
  footColors = ''
    [colors]
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

  # Pywal-compatible colors.json for pywalfox (raw Jinja2 template, no leading whitespace)
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

  # Wallust config template generator
  mkWallustConfig = {extraTemplates ? ""}: ''
    backend = "fastresize"
    color_space = "lch"
    palette = "dark"
    check_contrast = true

    [templates]
    # Shared CSS variables - importable by GTK, browsers, Discord, etc.
    colors-css = { template = "colors.css", target = "~/.cache/wallust/colors.css" }

    # Pywal-compatible colors.json for pywalfox
    pywal-colors = { template = "colors.json", target = "~/.cache/wal/colors.json" }

    # Foot terminal colors (cache-only theming)
    foot-colors = { template = "foot-colors.ini", target = "~/.cache/wallust/colors_foot.ini" }

    # Zellij templates
    zellij-config = { template = "zellij-config.kdl", target = "~/.config/zellij/config.kdl" }
    zellij-layout = { template = "zellij-layout.kdl", target = "~/.config/zellij/layouts/zjstatus.kdl" }
    ${extraTemplates}
  '';

  # Generate full zellij config.kdl template (base config + theme)
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

          // Global defaults
          key_fg "#000000"
          key_bg "#FFFFFF"
          label_fg "#FFFFFF"
          label_bg "#333333"

          // ═══════════════════════════════════════════════════════════
          // NORMAL MODE - Mode switchers (rainbow base colors)
          // ═══════════════════════════════════════════════════════════
          pane_key_bg "#FF3355"
          pane_label_bg "#991133"
          tab_key_bg "#33FF88"
          tab_label_bg "#119944"
          resize_key_bg "#3388FF"
          resize_label_bg "#1144AA"
          move_key_bg "#FFDD33"
          move_label_bg "#AA8800"
          scroll_key_bg "#DD55FF"
          scroll_label_bg "#8822AA"
          search_key_bg "#33DDFF"
          search_label_bg "#1188AA"
          session_key_bg "#FF8833"
          session_label_bg "#AA4400"
          quit_key_bg "#FF3388"
          quit_label_bg "#AA1155"

          // ═══════════════════════════════════════════════════════════
          // PANE MODE - Red family (mode-specific with dots)
          // ═══════════════════════════════════════════════════════════
          "pane.new_key_bg" "#FF5566"
          "pane.new_label_bg" "#AA2233"
          "pane.close_key_bg" "#FF4455"
          "pane.close_label_bg" "#992233"
          fullscreen_key_bg "#FF6677"
          fullscreen_label_bg "#AA3344"
          float_key_bg "#FF7788"
          float_label_bg "#AA4455"
          embed_key_bg "#FF8899"
          embed_label_bg "#AA5566"
          split_right_key_bg "#FF99AA"
          split_right_label_bg "#AA6677"
          split_down_key_bg "#FFAABB"
          split_down_label_bg "#AA7788"
          "pane.rename_key_bg" "#FFBBCC"
          "pane.rename_label_bg" "#AA8899"
          "pane.move_key_bg" "#FF6688"
          "pane.move_label_bg" "#AA3355"
          "pane.select_key_bg" "#FF7799"
          "pane.select_label_bg" "#AA4466"

          // ═══════════════════════════════════════════════════════════
          // TAB MODE - Green family (mode-specific with dots)
          // ═══════════════════════════════════════════════════════════
          "tab.new_key_bg" "#55FF99"
          "tab.new_label_bg" "#22AA55"
          "tab.close_key_bg" "#44EE88"
          "tab.close_label_bg" "#119944"
          break_pane_key_bg "#66FFAA"
          break_pane_label_bg "#33AA66"
          sync_key_bg "#77FFBB"
          sync_label_bg "#44AA77"
          "tab.rename_key_bg" "#88FFCC"
          "tab.rename_label_bg" "#55AA88"
          "tab.move_key_bg" "#99FFDD"
          "tab.move_label_bg" "#66AA99"
          "tab.select_key_bg" "#AAFFEE"
          "tab.select_label_bg" "#77AAAA"

          // ═══════════════════════════════════════════════════════════
          // RESIZE MODE - Blue family
          // ═══════════════════════════════════════════════════════════
          // resize reuses mode switcher color
          increase_key_bg "#55AAFF"
          increase_label_bg "#2266BB"
          decrease_key_bg "#4499EE"
          decrease_label_bg "#1155AA"

          // ═══════════════════════════════════════════════════════════
          // SCROLL MODE - Magenta family
          // ═══════════════════════════════════════════════════════════
          // scroll, search reuse mode switcher colors
          page_key_bg "#EE66FF"
          page_label_bg "#9933AA"
          half_page_key_bg "#DD77FF"
          half_page_label_bg "#8844AA"
          edit_key_bg "#CC88FF"
          edit_label_bg "#7755AA"

          // ═══════════════════════════════════════════════════════════
          // SEARCH MODE - Cyan family
          // ═══════════════════════════════════════════════════════════
          // search, scroll, page, half page reuse colors
          down_key_bg "#44EEFF"
          down_label_bg "#2299AA"
          up_key_bg "#55FFFF"
          up_label_bg "#33AAAA"

          // ═══════════════════════════════════════════════════════════
          // SESSION MODE - Orange family
          // ═══════════════════════════════════════════════════════════
          detach_key_bg "#FF9944"
          detach_label_bg "#AA5500"
          manager_key_bg "#FFAA55"
          manager_label_bg "#AA6611"
          config_key_bg "#FFBB66"
          config_label_bg "#AA7722"
          plugins_key_bg "#FFCC77"
          plugins_label_bg "#AA8833"
          about_key_bg "#FFDD88"
          about_label_bg "#AA9944"

          // ═══════════════════════════════════════════════════════════
          // SHARED - Used across multiple modes
          // ═══════════════════════════════════════════════════════════
          select_key_bg "#AAAAAA"
          select_label_bg "#555555"
          normal_key_bg "#888888"
          normal_label_bg "#444444"
        }
      }

      load_plugins {
        zjstatus-hints
      }
    ''}

    ${zellijTheme}
  '';

  # zjstatus layout with dynamic colors in hints bar
  zjstatusLayout = ''
    layout {
      default_tab_template {
        pane size=1 borderless=true {
          plugin location="https://github.com/dj95/zjstatus/releases/download/v0.21.1/zjstatus.wasm" {
            format_left   ""
            format_center "#[bg=yellow,fg=black,bold] {session} #[bg=reset,fg=reset] {mode} {tabs} #[bg=cyan,fg=black,bold] {datetime}"
            format_right  ""
            format_space  ""

            session "{name}"
            format_hide_on_overlength "true"
            format_precedence "lrc"

            border_enabled  "false"
            hide_frame_for_single_pane "false"

            // Mode badges
            mode_normal        "#[bg=blue,fg=black,bold] NORMAL "
            mode_locked        "#[bg=red,fg=white,bold] LOCKED "
            mode_resize        "#[bg=yellow,fg=black,bold] RESIZE "
            mode_pane          "#[bg=green,fg=black,bold] PANE "
            mode_tab           "#[bg=yellow,fg=black,bold] TAB "
            mode_scroll        "#[bg=magenta,fg=white,bold] SCROLL "
            mode_enter_search  "#[bg=magenta,fg=white,bold] SEARCH "
            mode_search        "#[bg=magenta,fg=white,bold] SEARCH "
            mode_rename_tab    "#[bg=yellow,fg=black,bold] RENAME "
            mode_rename_pane   "#[bg=green,fg=black,bold] RENAME "
            mode_session       "#[bg=magenta,fg=white,bold] SESSION "
            mode_move          "#[bg=yellow,fg=black,bold] MOVE "
            mode_prompt        "#[bg=magenta,fg=white,bold] PROMPT "
            mode_tmux          "#[bg=red,fg=white,bold] TMUX "

            // Tabs
            tab_normal              "#[bg=bright_black,fg=black] {name} {floating_indicator}"
            tab_normal_fullscreen   "#[bg=bright_black,fg=black] {name} [] {floating_indicator}"
            tab_normal_sync         "#[bg=bright_black,fg=black] {name} <> {floating_indicator}"
            tab_active              "#[bg=cyan,fg=black,bold] {name} {floating_indicator}"
            tab_active_fullscreen   "#[bg=cyan,fg=black,bold] {name} [] {floating_indicator}"
            tab_active_sync         "#[bg=cyan,fg=black,bold] {name} <> {floating_indicator}"
            tab_floating_indicator  "⬚ "

            datetime          "#[bg=cyan,fg=black,bold] {format} "
            datetime_format   "%d/%m/%y %H:%M:%S"
            datetime_timezone "Canada/Toronto"
          }
        }
        children
        pane size=1 borderless=true {
          plugin location="https://github.com/dj95/zjstatus/releases/download/v0.21.1/zjstatus.wasm" {
            format_left   ""
            format_center "{pipe_zjstatus_hints}"
            format_right  ""
            format_space  ""

            border_enabled  "false"
            hide_frame_for_single_pane "false"

            pipe_zjstatus_hints_format "{output}"
            pipe_zjstatus_hints_rendermode "raw"
          }
        }
      }
    }
  '';

  # Zellij theme with dynamic RGB colors
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
          base {{ color4 | red }} {{ color4 | green }} {{ color4 | blue }}
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
}
