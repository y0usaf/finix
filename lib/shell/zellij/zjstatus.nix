_: {
  # Top status bar - MAXIMUM DOPAMINE EDITION
  # Inverted colors for POP: bg=color, fg=black instead of subtle fg=color
  # Colors track terminal palette via ANSI names
  zjstatusTopBar = ''
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

      // Mode badges - INVERTED for maximum visibility
      // Each mode is a colored badge you can't miss
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

      // Tabs - active POPS with inverted cyan, inactive is subtle
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
  '';

  # Bottom status bar - hints with color styling
  # Fallback: hardcoded dopamine colors (used when wallust is disabled)
  # When wallust is enabled, it templates these colors dynamically
  zjstatusHintsBar = ''
    plugin location="https://github.com/dj95/zjstatus/releases/download/v0.21.1/zjstatus.wasm" {
      format_left   ""
      format_center "#[fg=#00ffb3,bg=#0a0a0f]{pipe_zjstatus_hints}"
      format_right  ""
      format_space  ""

      border_enabled  "false"
      hide_frame_for_single_pane "false"

      pipe_zjstatus_hints_format "#[fg=#ffbe0b,bg=#0a0a0f,bold]{output}"
      pipe_zjstatus_hints_rendermode "static"
    }
  '';
}
