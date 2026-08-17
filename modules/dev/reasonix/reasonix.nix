{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  cfg = config.user.dev.reasonix;
  inherit (pkgs.stdenv.hostPlatform) system;
  package = flakeInputs.reasonix-flake.packages."${system}".default;

  # Idempotent: sync the gateway key from apiKeyFile into
  # ~/.reasonix/.env (rewrite only when changed), then continue. Shared by
  # the CLI and desktop wrappers — reasonix reads api_key_env exclusively
  # from its global .env, never process env.
  seedKey = ''
    state_home="''${REASONIX_STATE_HOME:-$HOME/.reasonix}"
    env_file="$state_home/.env"
    if [ -r ${lib.escapeShellArg cfg.apiKeyFile} ]; then
      key="$(${pkgs.coreutils}/bin/tr -d '[:space:]' < ${lib.escapeShellArg cfg.apiKeyFile})"
      if [ -n "$key" ] && ! ${pkgs.gnugrep}/bin/grep -qxF "AI_GATEWAY_API_KEY=$key" "$env_file" 2>/dev/null; then
        ${pkgs.coreutils}/bin/mkdir -p "$state_home"
        tmp="$(${pkgs.coreutils}/bin/mktemp "$state_home/.env.XXXXXX")"
        {
          echo "AI_GATEWAY_API_KEY=$key"
          ${pkgs.gnugrep}/bin/grep -v '^AI_GATEWAY_API_KEY=' "$env_file" 2>/dev/null || true
        } > "$tmp"
        ${pkgs.coreutils}/bin/chmod 600 "$tmp"
        ${pkgs.coreutils}/bin/mv "$tmp" "$env_file"
      fi
    fi
  '';

  # Prebuilt desktop (Wails shell). Source build is disproportionate: Wails
  # can't cross-compile the CGO/WebKit binary and needs the wails CLI +
  # pnpm 10 + generated bindings; upstream ships native-runner artifacts
  # instead. Only reasonix-desktop is dynamic (WebKitGTK 4.1/GTK3); the
  # sibling launcher/guard binaries are static updater machinery we skip —
  # Nix owns updates.
  desktopPackage = pkgs.stdenv.mkDerivation {
    pname = "reasonix-desktop";
    version = "1.25.1";
    src = pkgs.fetchurl {
      url = "https://github.com/esengine/DeepSeek-Reasonix/releases/download/desktop-v1.25.1/Reasonix-linux-amd64.tar.gz";
      hash = "sha256-rpBp+EDUxII6IyEF9gU3J9I+ZQfn1EeviGxDPt0p9Q4=";
    };

    sourceRoot = ".";
    nativeBuildInputs = [pkgs.autoPatchelfHook];
    buildInputs = [
      pkgs.webkitgtk_4_1
      pkgs.gtk3
      pkgs.gdk-pixbuf
      pkgs.libsoup_3
      pkgs.glib
    ];
    installPhase = ''
      runHook preInstall
      install -Dm755 reasonix-desktop "$out/bin/reasonix-desktop"
      runHook postInstall
    '';
    meta = {
      description = "Reasonix desktop (Wails shell)";
      homepage = "https://github.com/esengine/deepseek-reasonix";
      license = lib.licenses.mit;
      platforms = ["x86_64-linux"];
      mainProgram = "reasonix-desktop";
    };
  };

  desktopWrapper = pkgs.writeShellScriptBin "reasonix-desktop" ''

    ${seedKey}

    # WebKitGTK ignores gtk-xft-dpi (what scales other GTK apps here) and

    # drops GDK_DPI_SCALE on the Wayland backend, so the webview renders at

    # 1x — tiny on a 1.5x system. Force XWayland where GDK_DPI_SCALE applies

    # and match user.ui.gtk.scale (the same value the GTK module exports).

    export GDK_BACKEND=x11

    # XWayland + NVIDIA: WebKitGTK's default DMA-BUF renderer blanks the

    # webview (compositing-mode off does not help). Force the legacy GL

    # renderer — the README's NVIDIA fallback.

    export WEBKIT_DISABLE_DMABUF_RENDERER=1

    export GDK_DPI_SCALE=${toString config.user.ui.gtk.scale}

    exec ${desktopPackage}/bin/reasonix-desktop "$@"

  '';
in {
  options.user.dev.reasonix = {
    enable = lib.mkEnableOption "reasonix cache-first DeepSeek coding agent";

    apiKeyFile = lib.mkOption {
      type = lib.types.str;
      example = "/home/y0usaf/Tokens/AI_GATEWAY_API_KEY.txt";
      description = ''
        Path (string, not path literal) to a file containing the Vercel AI
        Gateway key. The `reasonix` wrapper seeds it into the global
        $REASONIX_STATE_HOME/.env at launch — never into the Nix store.
        Reasonix resolves api_key_env only against that .env, not process env.
      '';
    };

    desktop.enable = lib.mkEnableOption "reasonix desktop (Wails shell)";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      [
        (pkgs.writeShellScriptBin "reasonix" ''
          ${seedKey}
          # --yolo auto-approves approval-gated tool calls for interactive
          # sessions (same runtime posture as Ctrl+Y). But it MUST be skipped
          # for the headless acp subcommand: `reasonix --yolo acp` forces the
          # bubbletea TUI, which dies with "error opening TTY" when paseo
          # spawns it on stdio with no terminal.
          for a in "$@"; do
            if [ "$a" = "acp" ]; then
              exec ${package}/bin/reasonix "$@"
            fi
            case "$a" in
              -*);;
              *) break;;
            esac
          done
          exec ${package}/bin/reasonix --yolo "$@"
        '')
      ]
      ++ lib.optionals cfg.desktop.enable [
        desktopWrapper
      ];

    # App-menu entry — same manzil user-file pattern as hermes.nix.

    # ~/.local/share/applications is globbed by the tui-launcher and any

    # niri app menu. Exec goes through the wrapper so the API key is seeded

    # before first launch (desktop reads the same global .env).

    manzil.users."${config.user.name}".files =
      {
        # Provider + default model, merged into the mutable ~/.reasonix/config.toml

        # at activation (manzil merge; login rewrites survive, patches re-merge).

        # Replaces the providers array: the stock deepseek-flash/deepseek-pro

        # entries needed DEEPSEEK_API_KEY, which doesn't exist in ~/Tokens.

        # check_updates=false: the Nix store is read-only, so the desktop

        # self-updater can never replace the binary — Nix owns updates.

        ".reasonix/config.toml" = {
          type = "merge";

          format = "toml";

          clobber = true;

          value = {
            default_model = "deepseek-flash-0731";

            # No anonymous usage stats: cli_metrics=off suppresses the CLI
            # consent prompt entirely.
            telemetry.cli_metrics = "off";

            # CLI YOLO: --yolo auto-approves approval-gated tool calls for this
            # session (same runtime mode as Ctrl+Y). permissions.mode below is
            # only a headless-run writer fallback; it does NOT affect the
            # interactive CLI's approval posture, so the flag is the real switch.
            permissions.mode = "allow";

            sandbox.bash = "off";

            desktop.check_updates = false;

            providers = [
              {
                name = "deepseek-flash-0731";

                kind = "openai";

                base_url = "https://ai-gateway.vercel.sh/v1";

                model = "deepseek-v4-flash-0731";

                api_key_env = "AI_GATEWAY_API_KEY";

                context_window = 1000000;
              }

              {
                name = "deepseek-pro";

                kind = "openai";

                base_url = "https://ai-gateway.vercel.sh/v1";

                model = "deepseek/deepseek-v4-pro-0813";

                api_key_env = "AI_GATEWAY_API_KEY";

                context_window = 1000000;
              }
            ];
          };
        };
      }
      // lib.optionalAttrs cfg.desktop.enable {
        ".local/share/applications/reasonix.desktop" = {
          generator = lib.generators.toINI {};

          value."Desktop Entry" = {
            Name = "Reasonix";

            Comment = "Cache-first DeepSeek coding agent (desktop)";

            Exec = "reasonix-desktop %U";

            Terminal = "false";

            Type = "Application";

            Categories = "Development;Utility;";

            Keywords = "ai;agent;assistant;deepseek;reasonix";
          };
        };
      };
  };
}
