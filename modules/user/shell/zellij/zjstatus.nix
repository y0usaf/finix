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
      format_center "#[bg=#3c3c3c,fg=#00ff64,bold] {session} #[bg=reset,fg=reset] {mode} {tabs} #[bg=#3c3c3c,fg=#00ff64,bold] {datetime}"
      format_right  ""
      format_space  ""

      session "{name}"
      format_hide_on_overlength "true"
      format_precedence "lrc"

      border_enabled  "false"
      hide_frame_for_single_pane "false"

      mode_normal        "#[bg=#3c3c3c,fg=#00c8ff,bold] NORMAL "
      mode_locked        "#[bg=#3c3c3c,fg=#ff0064,bold] LOCKED "
      mode_resize        "#[bg=#3c3c3c,fg=#ff6400,bold] RESIZE "
      mode_pane          "#[bg=#3c3c3c,fg=#00ff64,bold] PANE "
      mode_tab           "#[bg=#3c3c3c,fg=#ff6400,bold] TAB "
      mode_scroll        "#[bg=#3c3c3c,fg=#c800ff,bold] SCROLL "
      mode_enter_search  "#[bg=#3c3c3c,fg=#c800ff,bold] SEARCH "
      mode_search        "#[bg=#3c3c3c,fg=#c800ff,bold] SEARCH "
      mode_rename_tab    "#[bg=#3c3c3c,fg=#ff6400,bold] RENAME "
      mode_rename_pane   "#[bg=#3c3c3c,fg=#00ff64,bold] RENAME "
      mode_session       "#[bg=#3c3c3c,fg=#c800ff,bold] SESSION "
      mode_move          "#[bg=#3c3c3c,fg=#ff6400,bold] MOVE "
      mode_prompt        "#[bg=#3c3c3c,fg=#00ff64,bold] PROMPT "
      mode_tmux          "#[bg=#3c3c3c,fg=#ff6400,bold] TMUX "

      tab_normal              "#[bg=#3c3c3c,fg=#b4b4b4] {name} {floating_indicator}"
      tab_normal_fullscreen   "#[bg=#3c3c3c,fg=#b4b4b4] {name} [] {floating_indicator}"
      tab_normal_sync         "#[bg=#3c3c3c,fg=#b4b4b4] {name} <> {floating_indicator}"
      tab_active              "#[bg=#3c3c3c,fg=#00ff96,bold,italic] {name} {floating_indicator}"
      tab_active_fullscreen   "#[bg=#3c3c3c,fg=#00ff96,bold,italic] {name} [] {floating_indicator}"
      tab_active_sync         "#[bg=#3c3c3c,fg=#00ff96,bold,italic] {name} <> {floating_indicator}"
      tab_floating_indicator  "⬚ "

      datetime        "#[bg=#3c3c3c,fg=#00ff64,bold]{format} "
      datetime_format "%d/%m/%y %H:%M:%S"
    }
  '';

  # Bottom status bar - centered hints
  zjstatusHintsBar = ''
    plugin location="file:${zjstatusPackage}/bin/zjstatus.wasm" {
      format_left   ""
      format_center "#[fg=#00ff64,bg=#0f0f0f]{pipe_zjstatus_hints}"
      format_right  ""
      format_space  ""

      border_enabled  "false"
      hide_frame_for_single_pane "false"

      pipe_zjstatus_hints_format "#[fg=#00ff64,bg=#000000,bold]{output}"
      pipe_zjstatus_hints_rendermode "raw"
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
