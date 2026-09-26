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

    export GDK_BACKEND=x11

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
      ++ lib.optional cfg.desktop.enable desktopWrapper;

    manzil.users."${config.user.name}".files =
      {
        ".reasonix/REASONIX.md" = {
          type = "copy";
          text = config.user.dev.prompts.ethics + "\n\n" + config.user.dev.prompts.noTests + "\n\n" + config.user.dev.prompts.noComments;
        };

        ".reasonix/config.toml" = {
          type = "merge";

          format = "toml";

          clobber = true;

          value = {
            default_model = "glm-5.3-flash";

            telemetry.cli_metrics = "off";

            permissions.mode = "allow";

            sandbox.bash = "off";

            desktop.check_updates = false;

            providers = [
              {
                name = "glm-5.3-flash";

                kind = "openai";

                base_url = "https://ai-gateway.vercel.sh/v1";

                model = "glm-5.3-flash";

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
