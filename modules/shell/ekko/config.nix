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
    manzil.users."${config.user.name}".files =
      {
        # The which-key.lua user extension rebuilds the leader mode and the
        # status/hint bar in Lua; the builtin leader and statusbar MUST stay
        # disabled or the runtime aborts with duplicate leader-mode
        # keybindings on attach. The builtin sidebar (visible: None = always
        # shown) is replaced by the lua leader-attached session panel. The
        # builtin panes extension registers leader h/j/k/l/x/|/- for
        # split/focus/close — its j/k/x collide with which-key.lua's own
        # leader keys, so it is disabled too; pane keys live in the lua map
        # instead. Vendored alongside this module (which-key.lua) so every
        # host gets it — it used to live hand-managed on one machine, and
        # hosts without it lost the entire leader/status UI.
        ".config/ekko/extensions/which-key.lua".source = ./which-key.lua;

        # Unbind project navigation: "none" is intentionally unparseable —
        # resolve_chords skips the action entirely (empty string would fall
        # back to the defaults instead).
        ".config/ekko/config.toml" = {
          text = ''
            [extensions]
            disabled = ["ekko-builtins.leader", "ekko-builtins.statusbar", "ekko-builtins.sidebar", "ekko-builtins.panes"]

            [keybinds]
            project_prev = "none"
            project_next = "none"

            # Zellij-style pane borders: a full box frame around every pane,
            # the focused pane's frame tinted with the theme accent. Swap to
            # "compact" for zellij's compact mode (single shared boundary
            # lines with junction glyphs). The daemon owns the canvas, so
            # this takes effect for newly started sessions (ekko kill).
            [ui]
            pane_borders = "frame"
          '';
        };
      }
      // lib.optionalAttrs (ekko.autoStart && lib.attrByPath ["user" "shell" "nushell" "enable"] false config) {
        ".config/nushell/config.nu" = {
          text = lib.mkAfter ''
            source ~/.config/nushell/ekko.nu
          '';
        };
        ".config/nushell/ekko.nu" = {
          text = ''
            # Skip if already in a multiplexer or SSH session
            if ("EKKO_SESSION_NAME" in $env) or ("SSH_CONNECTION" in $env) or ("TMUX" in $env) { return }

            # Skip if in virtual console
            if ($env.TERM? | default "") == "linux" { return }

            exec ekko
          '';
        };
      }
      // lib.optionalAttrs (ekko.autoStart && lib.attrByPath ["user" "shell" "zsh" "enable"] false config) {
        ".config/zsh/.zshrc" = {
          text = lib.mkAfter ''
            source "$ZDOTDIR/ekko.zsh"
          '';
        };
        ".config/zsh/ekko.zsh" = {
          text = ''
            # Skip if already in a multiplexer or SSH session (fast: variable checks only)
            [[ -n "$EKKO_SESSION_NAME" || -n "$SSH_CONNECTION" || -n "$TMUX" ]] && return

            # Skip if in virtual console
            [[ "$TERM" == "linux" ]] && return

            # Robust fallback: device path check (minimal subprocess overhead)
            [[ $(readlink /proc/self/fd/0 2>/dev/null) =~ ^/dev/tty[0-9] ]] && return

            exec ekko
          '';
        };
      };
  };
}
