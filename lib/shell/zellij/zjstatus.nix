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

  # Custom keybind hints with global modifier extraction and label text overrides
  # Uses local dev build to test customization features
  # Common modifiers (e.g., Ctrl) are displayed once on far left, keys without duplication
  zjstatusHintsCustom = ''
    plugin location="/home/y0usaf/Dev/zjstatus-hints-fork/target/wasm32-wasip1/debug/zjstatus_hints.wasm" {
      // Format: just show keys since Ctrl is extracted and shown on the left
      key_format "{keys}"

      // Global color configuration
      key_fg "#000000"
      key_bg "#00ffb3"
      label_fg "#e0e0ff"
      label_bg "#0a0a0f"

      // Label text overrides - unicode fullwidth characters for modes
      // Modes (use fullwidth characters)
      pane_label_text "ｐ"
      tab_label_text "ｔ"
      resize_label_text "ｒ"
      move_label_text "ｍ"
      scroll_label_text "ｓｃ"
      search_label_text "ｓｈ"
      session_label_text "ｓｓ"

      // Actions (unicode glyphs for better visual variety)
      split_right_label_text "→"
      split_down_label_text "↓"
      new_label_text "ｎ"
      close_label_text "✕"
      fullscreen_label_text "◻"
      float_label_text "◈"
      embed_label_text "⊙"
      rename_label_text "◐"
      select_label_text "✓"
      break_pane_label_text "⊥"
      sync_label_text "⇄"
    }
  '';
}
