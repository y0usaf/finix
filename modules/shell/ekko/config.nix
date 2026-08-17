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
      # The which-key WASM extension rebuilds the leader mode and the
      # status/hint bar as a compiled `.wasm` module on the cordis kernel (the
      # Rust guest in the ekko repo, package `which-key`, built to
      # wasm32-unknown-unknown). The builtin leader and statusbar MUST stay
      # disabled or the runtime aborts with duplicate leader-mode
      # keybindings on attach. The builtin sidebar (visible: None = always
      # shown) is replaced by the leader-attached session panel. The builtin
      # panes extension registers pane operations and leader keys that collide
      # with which-key's own leader keys, so it is disabled too; pane keys
      # live in the wasm map instead. Vendored via the ekko flake input so
      # every host gets it deterministically. Note: `packages.which-key` is
      # the derivation's *output* (a dir containing which-key.wasm); point at
      # the file inside it so manzil symlinks a file, not a directory.
      ".config/ekko/extensions/which-key.wasm".source =
        flakeInputs.ekko.packages."${pkgs.stdenv.hostPlatform.system}".which-key
        + "/which-key.wasm";

      # The WASM config module (cordis set 1): on mount it ctx_set's the
      # `config` key with the settings JSON, reproducing the former init.lua.
      # Builtin leader/statusbar/sidebar/panes/keybindings are disabled
      # (which-key owns those surfaces); pane borders framed with ASCII
      # glyphs, equal layout, 33ms animation tick.
      ".config/ekko/config.wasm".source = ./config.wasm;
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
