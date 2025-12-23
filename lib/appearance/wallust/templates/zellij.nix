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

          // Global defaults - ANSI colors for wallust hot-swap
          // Unified black text with bright backgrounds for readability
          key_fg "black"
          key_bg "white"
          label_fg "black"
          label_bg "white"

          // ═══════════════════════════════════════════════════════════
          // NORMAL MODE - Mode switchers (bright backgrounds)
          // ═══════════════════════════════════════════════════════════
          pane_label_bg "bright_green"
          tab_label_bg "bright_yellow"
          resize_label_bg "bright_yellow"
          move_label_bg "bright_yellow"
          scroll_label_bg "bright_magenta"
          search_label_bg "bright_magenta"
          session_label_bg "bright_magenta"
          quit_label_bg "bright_red"

          // ═══════════════════════════════════════════════════════════
          // PANE MODE - Green
          // ═══════════════════════════════════════════════════════════
          "pane.new_label_bg" "bright_green"
          "pane.close_label_bg" "bright_red"
          fullscreen_label_bg "bright_cyan"
          float_label_bg "bright_cyan"
          embed_label_bg "bright_cyan"
          split_right_label_bg "bright_green"
          split_down_label_bg "bright_green"
          "pane.rename_label_bg" "bright_yellow"
          "pane.move_label_bg" "bright_yellow"
          "pane.select_label_bg" "bright_blue"

          // ═══════════════════════════════════════════════════════════
          // TAB MODE - Yellow
          // ═══════════════════════════════════════════════════════════
          "tab.new_label_bg" "bright_green"
          "tab.close_label_bg" "bright_red"
          break_pane_label_bg "bright_cyan"
          sync_label_bg "bright_magenta"
          "tab.rename_label_bg" "bright_yellow"
          "tab.move_label_bg" "bright_yellow"
          "tab.select_label_bg" "bright_blue"

          // ═══════════════════════════════════════════════════════════
          // RESIZE MODE - Yellow
          // ═══════════════════════════════════════════════════════════
          increase_label_bg "bright_green"
          decrease_label_bg "bright_red"

          // ═══════════════════════════════════════════════════════════
          // SCROLL MODE - Magenta
          // ═══════════════════════════════════════════════════════════
          page_label_bg "bright_magenta"
          half_page_label_bg "bright_magenta"
          edit_label_bg "bright_yellow"

          // ═══════════════════════════════════════════════════════════
          // SEARCH MODE - Magenta
          // ═══════════════════════════════════════════════════════════
          down_label_bg "bright_cyan"
          up_label_bg "bright_cyan"

          // ═══════════════════════════════════════════════════════════
          // SESSION MODE - Magenta
          // ═══════════════════════════════════════════════════════════
          detach_label_bg "bright_red"
          manager_label_bg "bright_cyan"
          config_label_bg "bright_yellow"
          plugins_label_bg "bright_green"
          about_label_bg "bright_blue"

          // ═══════════════════════════════════════════════════════════
          // SHARED - Used across multiple modes
          // ═══════════════════════════════════════════════════════════
          select_label_bg "bright_blue"
          normal_label_bg "bright_blue"
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
            format_center "#[bg=bright_yellow,fg=black,bold] {session} #[bg=reset,fg=reset] {mode} {tabs} #[bg=bright_cyan,fg=black,bold] {datetime}"
            format_right  ""
            format_space  ""

            session "{name}"
            format_hide_on_overlength "true"
            format_precedence "lrc"

            border_enabled  "false"
            hide_frame_for_single_pane "false"

            // Mode badges - unified black text on bright backgrounds
            mode_normal        "#[bg=bright_blue,fg=black,bold] NORMAL "
            mode_locked        "#[bg=bright_red,fg=black,bold] LOCKED "
            mode_resize        "#[bg=bright_yellow,fg=black,bold] RESIZE "
            mode_pane          "#[bg=bright_green,fg=black,bold] PANE "
            mode_tab           "#[bg=bright_yellow,fg=black,bold] TAB "
            mode_scroll        "#[bg=bright_magenta,fg=black,bold] SCROLL "
            mode_enter_search  "#[bg=bright_magenta,fg=black,bold] SEARCH "
            mode_search        "#[bg=bright_magenta,fg=black,bold] SEARCH "
            mode_rename_tab    "#[bg=bright_yellow,fg=black,bold] RENAME "
            mode_rename_pane   "#[bg=bright_green,fg=black,bold] RENAME "
            mode_session       "#[bg=bright_magenta,fg=black,bold] SESSION "
            mode_move          "#[bg=bright_yellow,fg=black,bold] MOVE "
            mode_prompt        "#[bg=bright_magenta,fg=black,bold] PROMPT "
            mode_tmux          "#[bg=bright_red,fg=black,bold] TMUX "

            // Tabs - unified black text on bright backgrounds
            tab_normal              "#[bg=white,fg=black] {name} {floating_indicator}"
            tab_normal_fullscreen   "#[bg=white,fg=black] {name} [] {floating_indicator}"
            tab_normal_sync         "#[bg=white,fg=black] {name} <> {floating_indicator}"
            tab_active              "#[bg=bright_cyan,fg=black,bold] {name} {floating_indicator}"
            tab_active_fullscreen   "#[bg=bright_cyan,fg=black,bold] {name} [] {floating_indicator}"
            tab_active_sync         "#[bg=bright_cyan,fg=black,bold] {name} <> {floating_indicator}"
            tab_floating_indicator  "⬚ "

            datetime          "#[bg=bright_cyan,fg=black,bold] {format} "
            datetime_format   "%d/%m/%y %H:%M:%S"
            datetime_timezone "Canada/Toronto"
          }
        }
        children
        pane size=1 borderless=true {
          plugin location="https://github.com/dj95/zjstatus/releases/download/v0.21.1/zjstatus.wasm" {
            format_left   ""
            format_center "#[fg=bright_cyan,bg=black]{pipe_zjstatus_hints}"
            format_right  ""
            format_space  ""

            border_enabled  "false"
            hide_frame_for_single_pane "false"

            pipe_zjstatus_hints_format "#[fg=bright_cyan,bg=black,bold]{output}"
            pipe_zjstatus_hints_rendermode "static"
          }
        }
      }
    }
  '';
}
