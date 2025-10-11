{
  config,
  lib,
  flakeInputs,
  ...
}: let
  cfg = config.user.shell.zellij;
  zjstatusPackage = flakeInputs.zjstatus.packages.${config.nixpkgs.system}.default;

  zjstatusBar = ''
    plugin location="file:${zjstatusPackage}/bin/zjstatus.wasm" {
      format_left   "{command_zjstatus_hints}"
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

      command_zjstatus_hints_command "cat /tmp/zjstatus_hints"
      command_zjstatus_hints_format  "{stdout}"
      command_zjstatus_hints_interval "1"
      command_zjstatus_hints_rendermode "static"
    }
  '';

  zjstatusHintsPane = lib.optionalString cfg.zjstatusHints.enable ''
    pane size=0 borderless=true {
      plugin location="file:${flakeInputs.zjstatus-hints.packages.${config.nixpkgs.system}.default}/bin/zjstatus-hints.wasm" {
        max_length ${toString cfg.zjstatusHints.maxLength}
        pipe_name "${cfg.zjstatusHints.pipeName}"
      }
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
            ${zjstatusHintsPane}
            children
            pane size=1 borderless=true {
              ${zjstatusBar}
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
