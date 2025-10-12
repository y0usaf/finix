{
  config,
  lib,
  flakeInputs,
  ...
}: let
  cfg = config.user.shell.zellij;
  zjstatusPackage = flakeInputs.zjstatus.packages.${config.nixpkgs.system}.default;

  # Top status bar - main status info
  zjstatusTopBar = ''
    plugin location="file:${zjstatusPackage}/bin/zjstatus.wasm" {
      format_left   ""
      format_center "#[bg=#00ff64,fg=#000000,bold] {session} #[bg=reset,fg=reset] {mode} {tabs} {datetime}"
      format_right  ""
      format_space  ""

      session "{name}"
      format_hide_on_overlength "true"
      format_precedence "lrc"

      border_enabled  "false"
      hide_frame_for_single_pane "false"

      mode_normal        "#[bg=#00c8ff,fg=#000000,bold] NORMAL "
      mode_locked        "#[bg=#ff0064,fg=#000000,bold] LOCKED "
      mode_resize        "#[bg=#ff6400,fg=#000000,bold] RESIZE "
      mode_pane          "#[bg=#00ff64,fg=#000000,bold] PANE "
      mode_tab           "#[bg=#ff6400,fg=#000000,bold] TAB "
      mode_scroll        "#[bg=#c800ff,fg=#000000,bold] SCROLL "
      mode_enter_search  "#[bg=#c800ff,fg=#000000,bold] SEARCH "
      mode_search        "#[bg=#c800ff,fg=#000000,bold] SEARCH "
      mode_rename_tab    "#[bg=#ff6400,fg=#000000,bold] RENAME "
      mode_rename_pane   "#[bg=#00ff64,fg=#000000,bold] RENAME "
      mode_session       "#[bg=#c800ff,fg=#000000,bold] SESSION "
      mode_move          "#[bg=#ff6400,fg=#000000,bold] MOVE "
      mode_prompt        "#[bg=#00ff64,fg=#000000,bold] PROMPT "
      mode_tmux          "#[bg=#ff6400,fg=#000000,bold] TMUX "

      tab_normal              "#[bg=#1f1f1f,fg=#b4b4b4] {index} {name} {floating_indicator}"
      tab_normal_fullscreen   "#[bg=#1f1f1f,fg=#b4b4b4] {index} {name} [] {floating_indicator}"
      tab_normal_sync         "#[bg=#1f1f1f,fg=#b4b4b4] {index} {name} <> {floating_indicator}"
      tab_active              "#[bg=#00ff96,fg=#000000,bold,italic] {index} {name} {floating_indicator}"
      tab_active_fullscreen   "#[bg=#00ff96,fg=#000000,bold,italic] {index} {name} [] {floating_indicator}"
      tab_active_sync         "#[bg=#00ff96,fg=#000000,bold,italic] {index} {name} <> {floating_indicator}"
      tab_floating_indicator  "⬚ "

      datetime        "#[bg=#00ff64,fg=#000000,bold] {format} "
      datetime_format "%d/%m/%y %H:%M:%S"
    }
  '';

  # Bottom status bar - centered hints
  zjstatusHintsBar = ''
    plugin location="file:${zjstatusPackage}/bin/zjstatus.wasm" {
      format_left   ""
      format_center "{pipe_zjstatus_hints}"
      format_right  ""
      format_space  ""

      border_enabled  "false"
      hide_frame_for_single_pane "false"

      pipe_zjstatus_hints_format "{output}"
    }
  '';
in {
  options.user.shell.zellij.zjstatus = {
    enable = lib.mkEnableOption "zjstatus plugin for zellij";

    layout = lib.mkOption {
      type = lib.types.lines;
      default = ''
        layout {
          default_tab_template {
            pane size=1 borderless=true {
              ${zjstatusTopBar}
            }
            children
            pane size=1 borderless=true {
              ${zjstatusHintsBar}
            }
          }
        }
      '';
      description = "Layout configuration for zjstatus. Customize via user.shell.zellij.zjstatus.layout option.";
    };
  };

  config = lib.mkIf (cfg.enable && cfg.zjstatus.enable) {
    usr.files.".config/zellij/layouts/zjstatus.kdl" = {
      clobber = true;
      text = cfg.zjstatus.layout;
    };
  };
}
