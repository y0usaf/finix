{
  config,
  lib,
  ...
}: let
  flakeDirectory = config.user.paths.flake.path;
in {
  options.user.shell = {
    aliases = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      description = ''
        Interactive aliases, rendered by whichever shell module is enabled.
        Values are escaped with `escapeShellArg`, so write them literally.
      '';
    };

    rcExtra = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        POSIX-compatible interactive rc fragments contributed by feature
        modules (python, nh, yt-dlp, ekko, …). Appended after the active
        shell's own base config.
      '';
    };
  };

  config = {
    user.shell.aliases =
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
  };
}
