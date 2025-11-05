{lib, ...}: let
  theme = import ./theme.nix {};
  zjstatus = import ./zjstatus.nix {};

  baseConfig = {
    hide_session_name = false;
    copy_on_select = true;
    show_startup_tips = false;
    on_force_close = "quit";
    session_serialization = false;
    pane_frames = true;
  };

  zjstatusUrl = "https://github.com/dj95/zjstatus/releases/download/v0.21.1/zjstatus.wasm";
  zjstatusHintsUrl = "https://github.com/b0o/zjstatus-hints/releases/latest/download/zjstatus-hints.wasm";

  shellIntegration = ''
    # Skip if already in a multiplexer or SSH session (fast: variable checks only)
    [[ -n "$ZELLIJ" || -n "$SSH_CONNECTION" || -n "$TMUX" ]] && return

    # Skip if in virtual console
    # Fast path: TERM check (no subprocess)
    [[ "$TERM" == "linux" ]] && return

    # Robust fallback: device path check (minimal subprocess overhead)
    [[ $(readlink /proc/self/fd/0 2>/dev/null) =~ ^/dev/tty[0-9] ]] && return

    exec zellij
  '';
in {
  inherit baseConfig shellIntegration theme zjstatus;
  inherit zjstatusUrl zjstatusHintsUrl;

  # Build complete KDL config attrs (caller will pass to genLib.toKDL)
  mkKdlAttrs = {
    zjstatusEnabled,
    userSettings,
  }:
    baseConfig
    // lib.optionalAttrs zjstatusEnabled {
      default_layout = "zjstatus";
    }
    // userSettings;

  # Build plugins and hints strings
  mkPluginsString = {zjstatusEnabled}:
    lib.optionalString zjstatusEnabled ''
      plugins {
        zjstatus-hints location="${zjstatusHintsUrl}" {
          max_length 0
          pipe_name "zjstatus_hints"
        }
      }

      load_plugins {
        zjstatus-hints
      }
    '';
}
