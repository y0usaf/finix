{lib, ...}: {
  config = {
    user.shell.zellij.zjstatus.layout = lib.mkDefault ''
      layout {
        default_tab_template {
          pane size=1 borderless=true {
            ${''
        plugin location="https://github.com/dj95/zjstatus/releases/download/v0.21.1/zjstatus.wasm" {
          format_left   ""
          format_center "#[fg=#e0e0ff,bold] [{session}] #[fg=#00ffff,bold] {mode} #[fg=#e0e0ff] {tabs} #[fg=#00ffff,bold] {datetime}"
          format_right  ""
          format_space  " "

          session "#[fg=#e0e0ff]{name}"
          format_hide_on_overlength "true"
          format_precedence "lrc"

          border_enabled  "false"
          hide_frame_for_single_pane "false"

          mode_normal        "#[fg=#00ffff,bold] [NORMAL] "
          mode_locked        "#[fg=#ff0055,bold] [LOCKED] "
          mode_resize        "#[fg=#ffcc00,bold] [RESIZE] "
          mode_pane          "#[fg=#00ff99,bold] [PANE] "
          mode_tab           "#[fg=#ffcc00,bold] [TAB] "
          mode_scroll        "#[fg=#ff00ff,bold] [SCROLL] "
          mode_enter_search  "#[fg=#ff00ff,bold] [SEARCH] "
          mode_search        "#[fg=#ff00ff,bold] [SEARCH] "
          mode_rename_tab    "#[fg=#ffcc00,bold] [RENAME] "
          mode_rename_pane   "#[fg=#00ff99,bold] [RENAME] "
          mode_session       "#[fg=#ff00ff,bold] [SESSION] "
          mode_move          "#[fg=#ffcc00,bold] [MOVE] "
          mode_prompt        "#[fg=#ff00ff,bold] [PROMPT] "
          mode_tmux          "#[fg=#ff0055,bold] [TMUX] "

          tab_normal              "#[fg=#e0e0ff] [{name}] {floating_indicator}"
          tab_normal_fullscreen   "#[fg=#e0e0ff] [{name}] [] {floating_indicator}"
          tab_normal_sync         "#[fg=#e0e0ff] [{name}] <> {floating_indicator}"
          tab_active              "#[fg=#00ffff,bold,underline] [{name}] {floating_indicator}"
          tab_active_fullscreen   "#[fg=#00ffff,bold,underline] [{name}] [] {floating_indicator}"
          tab_active_sync         "#[fg=#00ffff,bold,underline] [{name}] <> {floating_indicator}"
          tab_floating_indicator  "⬚ "

          datetime          "#[fg=#00ffff,bold] [{format}] "
          datetime_format   "%d/%m/%y %H:%M:%S"
          datetime_timezone "Canada/Toronto"
        }
      ''}
          }
          children
          pane size=1 borderless=true {
            ${''
        plugin location="https://github.com/dj95/zjstatus/releases/download/v0.21.1/zjstatus.wasm" {
          format_left   ""
          format_center "#[fg=#00ffb3]{pipe_zjstatus_hints}"
          format_right  ""
          format_space  " "

          border_enabled  "false"
          hide_frame_for_single_pane "false"

          pipe_zjstatus_hints_format "#[fg=#ffbe0b,bold]{output}"
          pipe_zjstatus_hints_rendermode "static"
        }
      ''}
          }
        }
      }
    '';
  };
}
