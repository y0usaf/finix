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
    # Opt-in finix behavior (not an ekko default): closing the session's
    # last pane while other alive sessions exist switches the client to the
    # nearest session instead of exiting the terminal. Implemented in the
    # vendored which-key.lua via the FINIX_CLOSE_TO_SESSION prologue below.
    closeToNearestSession = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Closing the focused last pane (ctrl+p then x) switches to the nearest
        alive session instead of exiting the terminal.
      '';
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

    # Opt-in finix behavior (not an ekko default): the WM terminal-spawn
    # path attaches to an existing alive session instead of spawning a
    # terminal whose shell starts a fresh one. Implemented in the
    # ekko-activate-or-terminal wrapper below.
    openAttachesExisting = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        The WM terminal-spawn bind attaches to an existing alive ekko
        session when no attached client exists to activate. Requires
        ekko.open.
      '';
    };
  };

  config = lib.mkIf ekko.enable {
    environment.systemPackages = [
      # The stock muxer + a small helper that first tries `ekko activate`,
      # then (optionally) attaches to an existing alive session, and only
      # then falls back to the regular terminal spawn.
      flakeInputs.ekko.packages."${pkgs.stdenv.hostPlatform.system}".default
      (pkgs.writeShellScriptBin "ekko-activate-or-terminal" ''
        # Monstar (the main terminal) rejects bare positional commands —
        # command forms need `-e` (foot-style positional args are not valid).
        # No-arg fallback stays plain so the terminal opens with $SHELL.
        run_in_terminal() {
          if [ "$#" -eq 0 ]; then
            exec ${config.user.defaults.terminal}
          fi
          exec ${config.user.defaults.terminal} -e "$@"
        }
        if ekko activate >/dev/null 2>&1; then
          exit 0
        fi
        ${lib.optionalString ekko.openAttachesExisting ''
          # No attached client: attach to the first alive session instead of
          # spawning a terminal whose shell would start a fresh one. `ekko ls`
          # states: attached | detached | resurrectable; activate already
          # covered attached, so detached is the interesting case here.
          name="$(ekko ls | awk -F '\t' '$2 == "detached" {print $1; exit}')"
          if [ -n "$name" ]; then
            run_in_terminal sh -c 'exec ekko attach "$1"' ekko-open "$name"
          fi
        ''}
        run_in_terminal "$@"
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
      # Vendored as text so finix options can inject a prologue: the
      # FINIX_CLOSE_TO_SESSION flag is read by the pane-close handler in the
      # file body (see closeToNearestSession above).
      ".config/ekko/extensions/which-key.lua".text =
        "local FINIX_CLOSE_TO_SESSION = "
        + (lib.boolToString ekko.closeToNearestSession)
        + "\n"
        + builtins.readFile ./which-key.lua;

      # Unbind project navigation: "none" is intentionally unparseable —
      # resolve_chords skips the action entirely (empty string would fall
      # back to the defaults instead).
      ".config/ekko/init.lua" = {
        text = ''
          return {
            extensions = {
              -- The entire stock chord set is disabled above; [keybinds] has
              -- nothing left to suppress.
              disabled = {
                "ekko-builtins.leader",
                "ekko-builtins.statusbar",
                "ekko-builtins.sidebar",
                "ekko-builtins.panes",
                "ekko-builtins.keybindings",
              },
            },
            ui = {
              -- Zellij-style pane borders: a full box frame around every pane,
              -- the focused pane's frame tinted with the theme accent. Swap to
              -- "compact" for zellij's compact mode (single shared boundary
              -- lines with junction glyphs). The daemon owns the canvas, so
              -- this takes effect for newly started sessions (ekko kill).
              pane_borders = "frame",
              -- Client-local ASCII separators: the daemon still reserves the
              -- separator cells, but the client renders them with these glyphs
              -- instead of the box-drawing table.
              border_glyphs = { horizontal = "-", vertical = "|", junction = "+" },
              -- Panes tile to the divisor-pair grid whose cells are closest to
              -- square in pixels (cell height counted twice); prime counts of
              -- five or more use one near-half proportional cut whose halves
              -- are themselves grids. The requested split axis is ignored and
              -- the whole layout recomputes on every add or close. The daemon
              -- owns the canvas, so this takes effect for newly started
              -- sessions (ekko kill).
              pane_layout = "equal",
              -- Drives the client's animation tick (default 80ms = 12.5fps; 33ms = 30fps).
              animation_interval_ms = 33,
            },
          }
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

      # Robust fallback: device path check (minimal subprocess overhead).
      # `case` glob, not `[[ =~ ]]`: rush has no regex match in `[[ ]]`,
      # so the `=~` form is a syntax error that aborts sourcing before
      # `exec ekko` ever runs.
      case "$(readlink /proc/self/fd/0 2>/dev/null)" in
        /dev/tty[0-9]*) return ;;
      esac

      exec ekko
    '');
  };
}
