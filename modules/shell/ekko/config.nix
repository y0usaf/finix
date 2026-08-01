{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (config.user.shell) ekko;
in {
  options.user.shell.ekko = {
    enable = lib.mkEnableOption "ekko terminal multiplexer";
    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Automatically attach an ekko session on shell startup";
    };
    open = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Route the WM terminal-spawn bind through ekko: with an attached
        client, request focus for that existing terminal; cold (no client),
        fall back to spawning the regular terminal. Read by the WM modules
        (tomoe).
      '';
    };
  };

  config = lib.mkIf ekko.enable {
    environment.systemPackages = [
      # The stock muxer + a small helper that first tries `ekko activate`,
      # then falls back to the regular terminal spawn when no client is
      # attached.
      flakeInputs.ekko.packages."${pkgs.stdenv.hostPlatform.system}".default
      (pkgs.writeShellScriptBin "ekko-activate-or-terminal" ''
        if ekko activate >/dev/null 2>&1; then
          exit 0
        fi
        exec ${config.user.defaults.terminal} "$@"
      '')
    ];
    manzil.users."${config.user.name}".files = {
      # The which-key.lua user extension rebuilds the leader mode and the
      # status/hint bar in Lua; the builtin leader and statusbar MUST stay
      # disabled or the runtime aborts with duplicate leader-mode
      # keybindings on attach. The builtin sidebar (visible: None = always
      # shown) is replaced by the lua leader-attached session panel. The
      # builtin panes extension registers pane operations and leader keys
      # that collide with which-key.lua's own leader keys, so it is disabled
      # too; pane keys live in the lua map instead. Vendored alongside this module (which-key.lua) so every
      # host gets it — it used to live hand-managed on one machine, and
      # hosts without it lost the entire leader/status UI.
      ".config/ekko/extensions/which-key.lua".source = ./which-key.lua;

      # Unbind project navigation: "none" is intentionally unparseable —
      # resolve_chords skips the action entirely (empty string would fall
      # back to the defaults instead).
      ".config/ekko/config.toml" = {
        text = ''
          [extensions]
          disabled = ["ekko-builtins.leader", "ekko-builtins.statusbar", "ekko-builtins.sidebar", "ekko-builtins.panes", "ekko-builtins.keybindings"]

          # The entire stock chord set is disabled above; [keybinds] has
          # nothing left to suppress.

          # Zellij-style pane borders: a full box frame around every pane,
          # the focused pane's frame tinted with the theme accent. Swap to
          # "compact" for zellij's compact mode (single shared boundary
          # lines with junction glyphs). The daemon owns the canvas, so
          # this takes effect for newly started sessions (ekko kill).
          [ui]
          pane_borders = "frame"
          # Panes are auto-tiled to exactly equal areas by recursively halving
          # along the longer axis, pixel-aware because a terminal cell is about
          # twice as tall as it is wide: 3 panes are full-height columns and 4
          # panes are a 2x2 grid. The requested split axis is ignored and the
          # whole layout recomputes on every add or close. The daemon owns the
          # canvas, so this takes effect for newly started sessions (ekko kill).
          pane_layout = "equal"
          # Drives the client's animation tick (default 80ms = 12.5fps; 33ms = 30fps).
          animation_interval_ms = 33
        '';
      };
    };

    # mkOrder 1600 > mkAfter's 1500: `exec ekko` replaces the shell, so
    # anything appended after it in the rc would never run in this process.
    user.shell.rcExtra = lib.mkIf ekko.autoStart (lib.mkOrder 1600 ''
      # Skip if already in a multiplexer or SSH session (variable checks only)
      [[ -n "$EKKO_SESSION_NAME" || -n "$SSH_CONNECTION" || -n "$TMUX" ]] && return

      # Skip in a virtual console
      [[ "$TERM" == "linux" ]] && return

      # Robust fallback: device path check (minimal subprocess overhead)
      [[ $(readlink /proc/self/fd/0 2>/dev/null) =~ ^/dev/tty[0-9] ]] && return

      exec ekko
    '');
  };
}
