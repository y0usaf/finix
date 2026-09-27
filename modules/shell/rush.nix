{
  config,
  lib,
  pkgs,
  ...
}: let
  wallustBin = "${pkgs.wallust}/bin/wallust";
  flakeDirectory = "${config.user.homeDirectory}/finix";
  aliases =
    {
      wget = ''wget --hsts-file="$XDG_DATA_HOME/wget-hsts"'';
      lintcheck = "clear; statix check .; deadnix .";
      lintfix = "clear; statix fix .; deadnix .";
      wallust = "wt";
      claude = "claude --allow-dangerously-skip-permissions";
      buncodex = "bunx --bun @openai/codex";
      gemini = "bunx --bun @google/gemini-cli@preview";
      "l." = ''lsd -A | grep -E "^\."'';
      la = "lsd -A --color=always --group-dirs=first --icon=always";
      ll = "lsd -l --color=always --group-dirs=first --icon=always";
      ls = "lsd -lA --color=always --group-dirs=first --icon=always";
      lt = "lsd -A --tree --color=always --group-dirs=first --icon=always";
      grep = "rg --color auto";
      dir = "dir --color=auto";
      egrep = "rg --color auto";
      fgrep = "rg -F --color auto";
      adb = ''HOME="$XDG_DATA_HOME/android" adb'';
      pkgs = "nix-store --query --requisites /run/current-system | cut -d- -f2- | sort | uniq | rg -i";
      pkgcount = "nix-store --query --requisites /run/current-system | cut -d- -f2- | sort | uniq | wc -l";
      buildtime = ''time (nix build "$NH_FLAKE#nixosConfigurations.$HOST.config.system.build.toplevel" --option eval-cache false)'';
      hmpull = "git -C ${flakeDirectory} fetch origin && git -C ${flakeDirectory} reset --hard origin/main";
    }
    // lib.optionalAttrs config.hardware.nvidia.enable {
      nvidia-settings = ''nvidia-settings --config="$XDG_CONFIG_HOME/nvidia/settings"'';
      gpupower = "sudo nvidia-smi -pl";
    };
in {
  options.user.shell.rcExtra = lib.mkOption {
    type = lib.types.lines;
    default = "";
    description = ''
      POSIX-compatible interactive rc fragments contributed by feature
      modules (python, nh, yt-dlp, ekko, …). Appended after the active
      shell's own base config.
    '';
  };

  config = {
    user.shell.rcExtra = lib.mkMerge [
      (lib.mkBefore ''
        temppkg() {
          if [ -z "$1" ]; then
            echo "Usage: temppkg package_name"
            return 1
          fi
          nix-shell -p "$1" --run "exec $SHELL"
        }

        temprun() {
          if [ -z "$1" ]; then
            echo "Usage: temprun <package-name> [args...]"
            return 1
          fi
          local pkg=$1
          shift
          nix run "nixpkgs#$pkg" -- "$@"
        }
        export NPM_CONFIG_TMP="$XDG_RUNTIME_DIR"/npm
      '')
      ''
        case ":$PATH:" in
          *":$HOME/.local/bin:"*) ;;
          *) PATH="$HOME/.local/bin:$PATH" ;;
        esac
      ''
    ];

    finix.persistence.allowlist.users.${config.user.name}.directories = [
      ".local/state/rush"
    ];
    environment.systemPackages = [
      pkgs.rush
      pkgs.bat
    ];

    manzil.users."${config.user.name}".files = {
      ".config/rush/profile.rush".text = ''
        . /etc/profile

        if command -v wallust >/dev/null 2>&1; then
          ${lib.concatMapStringsSep "\n" (dir: "mkdir -p \"$HOME/${dir}\"") [".cache/wal" ".cache/wallust" ".config/Vencord/settings" ".config/vesktop/settings"]}
          ${wallustBin} cs "$HOME/.config/wallust/colorschemes/pantera.json"
        fi

        for file_path in "$HOME/Tokens"/*; do
          [ -f "$file_path" ] || continue
          var_name=$(basename "$file_path" .txt)
          [ -n "$var_name" ] || continue
          case $var_name in
            ANTHROPIC_API_KEY | OPENAI_API_KEY) continue ;;
            *[!a-zA-Z0-9_]*) continue ;;
            [0-9]*) continue ;;
          esac
          content=$(cat "$file_path" 2>/dev/null) || continue
          [ -n "$content" ] || continue
          case $content in
            *-----* | *[[:cntrl:]]*) continue ;;
          esac
          export "$var_name=$content"
        done
        unset file_path var_name content
      '';

      ".config/rush/config.rush".text = lib.mkMerge [
        (lib.mkBefore ''

          rush_prompt() {
            rush_prompt_status=$?
            prompt segment --bold --fg green "$(prompt_pwd)"
            if test "$rush_prompt_status" = 0; then
              prompt segment --fg cyan '>'
            else
              prompt segment --fg red '>'
            fi
            prompt text ' '
          }

          rush_prompt_right() {
            prompt segment --fg bright-blue "$(date +'%Y-%m-%d %H:%M')"
          }

          ${lib.concatStringsSep "\n" (lib.mapAttrsToList
            (k: v: "alias ${lib.escapeShellArg k}=${lib.escapeShellArg v}")
            aliases)}
        '')
        config.user.shell.rcExtra
      ];
    };
  };
}
