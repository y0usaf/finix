# Zellij templates: config, layout, and theme
{lib}: rec {
  # Zellij theme with dynamic RGB colors
  theme = ''
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
          {% if "golden" in wallpaper %}
          base {{ color11 | red }} {{ color11 | green }} {{ color11 | blue }}
          {% elif "dopamine" in wallpaper %}
          base {{ color9 | red }} {{ color9 | green }} {{ color9 | blue }}
          {% elif "sunset-red" in wallpaper %}
          base {{ color9 | red }} {{ color9 | green }} {{ color9 | blue }}
          {% else %}
          base {{ color4 | red }} {{ color4 | green }} {{ color4 | blue }}
          {% endif %}
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

  # Generate full zellij config.kdl template (base config + theme)
  mkConfigTemplate = {zjstatusEnabled ? false}: ''
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

    ${theme}
  '';

  # zjstatus layout with dynamic colors in hints bar
  layout = ''
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
}
