{
  config,
  lib,
  pkgs,
  ...
}: let
  aliases =
    {
      wget = ''wget --hsts-file="$XDG_DATA_HOME/wget-hsts"'';
      lintcheck = "clear; statix check .; deadnix .";
      lintfix = "clear; statix fix .; deadnix .";
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
      hmpull = "git -C ${config.user.homeDirectory}/finix fetch origin && git -C ${config.user.homeDirectory}/finix reset --hard origin/main";
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
    environment.etc."profile.d/local-bin.sh".text = ''
      case ":$PATH:" in
        *":$HOME/.local/bin:"*) ;;
        *) export PATH="$HOME/.local/bin:$PATH" ;;
      esac
    '';

    user.shell.rcExtra = lib.mkBefore ''
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
    '';

    finix.persistence.allowlist.users.${config.user.name}.directories = [
      ".local/state/rush"
    ];
    environment.systemPackages = [
      pkgs.bat
    ];

    manzil.users."${config.user.name}".files = {
      ".config/rush/profile.rush".text = ''
        . /etc/profile
        [ -r "$HOME/.config/tokens.sh" ] && . "$HOME/.config/tokens.sh"
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
