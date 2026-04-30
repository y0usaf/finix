{
  config,
  lib,
  ...
}: let
  zjstatusEnabled = lib.attrByPath ["user" "shell" "zellij" "zjstatus" "enable"] false config;
in {
  config.user.appearance.wallust = {
    targets = {
      "zellij-config" = {
        template = "zellij-config.kdl";
        target = "~/.config/zellij/config.kdl";
      };
      "zellij-layout" = {
        template = "zellij-layout.kdl";
        target = "~/.config/zellij/layouts/zjstatus.kdl";
      };
    };

    templates."zellij-config.kdl" = ({zjstatusEnabled ? false}: ''
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

      ${''
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
              base {{ foreground | red }} {{ foreground | green }} {{ foreground | blue }}
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
              emphasis_3 {{ foreground | red }} {{ foreground | green }} {{ foreground | blue }}
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
      ''}
    '') {inherit zjstatusEnabled;};

    templates."zellij-layout.kdl" = ''
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

              mode_normal        "#[fg=#{{color14 | strip}},bold]NORMAL"
              mode_locked        "#[fg=#{{color1 | strip}},bold]LOCKED"
              mode_resize        "#[fg=#{{color11 | strip}},bold]RESIZE"
              mode_pane          "#[fg=#{{color10 | strip}},bold]PANE"
              mode_tab           "#[fg=#{{color11 | strip}},bold]TAB"
              mode_scroll        "#[fg=#{{color13 | strip}},bold]SCROLL"
              mode_enter_search  "#[fg=#{{color13 | strip}},bold]SEARCH"
              mode_search        "#[fg=#{{color13 | strip}},bold]SEARCH"
              mode_rename_tab    "#[fg=#{{color11 | strip}},bold]RENAME"
              mode_rename_pane   "#[fg=#{{color10 | strip}},bold]RENAME"
              mode_session       "#[fg=#{{color13 | strip}},bold]SESSION"
              mode_move          "#[fg=#{{color11 | strip}},bold]MOVE"
              mode_prompt        "#[fg=#{{color13 | strip}},bold]PROMPT"
              mode_tmux          "#[fg=#{{color1 | strip}},bold]TMUX"

              tab_normal              "#[fg=#{{foreground | strip}}][{name}] "
              tab_normal_fullscreen   "#[fg=#{{foreground | strip}}][{name} []] "
              tab_normal_sync         "#[fg=#{{foreground | strip}}][{name} <>] "
              tab_active              "#[fg=#{{color14 | strip}},bold,underline][{name}] "
              tab_active_fullscreen   "#[fg=#{{color14 | strip}},bold,underline][{name} []] "
              tab_active_sync         "#[fg=#{{color14 | strip}},bold,underline][{name} <>] "
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
  };
}
