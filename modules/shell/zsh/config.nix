{
  config,
  lib,
  pkgs,
  ...
}: let
  homeDir = config.user.homeDirectory;
  inherit (config.user) shell;
  inherit (shell) zellij;
  inherit (config.user) defaults;
  flakeDirectory = config.user.paths.flake.path;
  aliases =
    {
      wget = ''wget --hsts-file="$XDG_DATA_HOME/wget-hsts"'';
      lintcheck = "clear; statix check .; deadnix .";
      lintfix = "clear; statix fix .; deadnix .";
      wallust = "wt";
      claude = "claude --allow-dangerously-skip-permissions";
      buncodex = "bunx --bun @openai/codex";
      gemini = "bunx --bun @google/gemini-cli@preview";
      "l." = "lsd -A | grep -E \"^\\\\.\"";
      la = "lsd -A --color=always --group-dirs=first --icon=always";
      ll = "lsd -l --color=always --group-dirs=first --icon=always";
      ls = "lsd -lA --color=always --group-dirs=first --icon=always";
      lt = "lsd -A --tree --color=always --group-dirs=first --icon=always";
      grep = "rg --color auto";
      dir = "dir --color=auto";
      egrep = "rg --color auto";
      fgrep = "rg -F --color auto";
      svn = ''svn --config-dir "$XDG_CONFIG_HOME/subversion"'';
      adb = ''HOME="$XDG_DATA_HOME/android" adb'';
      mocp = ''mocp -M "$XDG_CONFIG_HOME/moc" -O MOCDir="$XDG_CONFIG_HOME/moc"'';
      yarn = ''yarn --use-yarnrc "$XDG_CONFIG_HOME/yarn/config"'';
      pkgs = "nix-store --query --requisites /run/current-system | cut -d- -f2- | sort | uniq | rg -i";
      pkgcount = "nix-store --query --requisites /run/current-system | cut -d- -f2- | sort | uniq | wc -l";
      buildtime = "time (nix build \${NH_FLAKE}#nixosConfigurations.\${HOST}.config.system.build.toplevel --option eval-cache false)";
      hmpush = "git -C ${flakeDirectory} push origin main --force";
      hmpull = "git -C ${flakeDirectory} fetch origin && git -C ${flakeDirectory} reset --hard origin/main";
    }
    // lib.optionalAttrs config.hardware.nvidia.enable {
      nvidia-settings = ''nvidia-settings --config="$XDG_CONFIG_HOME/nvidia/settings"'';
      gpupower = "sudo nvidia-smi -pl";
    };

  exportVars = ''
    export_vars_from_files() {
        local dir_path=$1

        if [[ ! -d "$dir_path" ]]; then
            return 0
        fi

        local skip_for_opencode=("ANTHROPIC_API_KEY" "OPENAI_API_KEY")

        for file_path in "$dir_path"/*; do
            if [[ -f $file_path ]]; then
                var_name=$(basename "$file_path" .txt)

                if [[ ! $var_name =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
                    continue
                fi

                if [[ " ''${skip_for_opencode[@]} " =~ " $var_name " ]]; then
                    continue
                fi

                local content=$(cat "$file_path" 2>/dev/null || echo "")
                if [[ -z "$content" ]] || [[ $content =~ [[:cntrl:]] ]] || [[ $content == *"-----"* ]]; then
                    continue
                fi

                export $var_name="$content"
            fi
        done
    }
    export_vars_from_files "${homeDir}/Tokens"
  '';

  historySettings = ''
    HISTSIZE=10000
    SAVEHIST=10000
    HISTFILE="${homeDir}/.local/state/zsh/history"
    setopt HIST_IGNORE_DUPS
    setopt HIST_IGNORE_ALL_DUPS
    setopt HIST_IGNORE_SPACE
    setopt HIST_EXPIRE_DUPS_FIRST
    setopt SHARE_HISTORY
    setopt EXTENDED_HISTORY
  '';

  completionSettings = ''
    zstyle ':completion:*' menu select
    zstyle ':completion:*' matcher-list \
        'm:{a-zA-Z}={A-Za-z}' \
        'r:|[._-]=* r:|=*' \
        'l:|=* r:|=*'
  '';

  promptSettings = ''
    PS1='%B%F{green}%~%b%f%(?.%B%F{cyan}.%B%F{red})>%f%b '
  '';

  pluginSettings = ''
    source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    ZSH_HIGHLIGHT_STYLES[default]='fg=10'
    ZSH_HIGHLIGHT_STYLES[command]='fg=6'
    ZSH_HIGHLIGHT_STYLES[builtin]='fg=6,bold'
    ZSH_HIGHLIGHT_STYLES[string]='fg=2'
    ZSH_HIGHLIGHT_STYLES[error]='fg=1,bold'
    ZSH_HIGHLIGHT_STYLES[comment]='fg=5'

    source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
  '';

  tempPkgFunction = ''
    temppkg() {
      if [ -z "$1" ]; then
        echo "Usage: temppkg package_name"
        return 1
      fi
      nix-shell -p "$1" --run "exec $SHELL"
    }
  '';

  tempRunFunction = ''
    temprun() {
      if [ -z "$1" ]; then
        echo "Usage: temprun <package-name> [args...]"
        return 1
      fi
      local pkg=$1
      shift
      nix run nixpkgs#$pkg -- "$@"
    }
  '';

  fanSpeedFunction =
    if config.networking.hostName == "y0usaf-laptop"
    then ''
      fanspeed() {
        if [ -z "$1" ]; then
          echo "Usage: fanspeed <percentage>"
          return 1
        fi
        local speed="$1"
        asusctl fan-curve -m quiet -D "30c:$speed,40c:$speed,50c:$speed,60c:$speed,70c:$speed,80c:$speed,90c:$speed,100c:$speed" -e true -f gpu
        asusctl fan-curve -m quiet -D "30c:$speed,40c:$speed,50c:$speed,60c:$speed,70c:$speed,80c:$speed,90c:$speed,100c:$speed" -e true -f cpu
      }
    ''
    else "";

  zellijShellChecks = ''
    # Skip if already in a multiplexer or SSH session (fast: variable checks only)
    [[ -n "$ZELLIJ" || -n "$SSH_CONNECTION" || -n "$TMUX" ]] && return

    # Skip if in virtual console
    [[ "$TERM" == "linux" ]] && return

    # Robust fallback: device path check (minimal subprocess overhead)
    [[ $(readlink /proc/self/fd/0 2>/dev/null) =~ ^/dev/tty[0-9] ]] && return
  '';

  zellijStartup =
    zellijShellChecks
    + ''
      # Start Zellij
      if [[ "$ZELLIJ_AUTO_ATTACH" == "true" ]]; then
        zellij attach -c
      else
        zellij
      fi

      if [[ "$ZELLIJ_AUTO_EXIT" == "true" ]]; then
        exit
      fi
    '';
in {
  options.user.shell.zsh = {
    enable = lib.mkEnableOption "zsh shell configuration";
  };
  config = lib.mkIf shell.zsh.enable {
    environment = {
      variables.ZDOTDIR = "${homeDir}/.config/zsh";
      systemPackages = [
        pkgs.zsh
        pkgs.bat
        pkgs.lsd
        pkgs.tree
        pkgs.zsh-syntax-highlighting
        pkgs.zsh-autosuggestions
      ];
    };
    programs.zsh.enable = true;

    bayt.users."${config.user.name}" = {
      files =
        {
          ".config/zsh/aliases.zsh" = {
            text = lib.concatStringsSep "\n" (
              lib.mapAttrsToList (k: v: "alias -- ${lib.escapeShellArg k}=${lib.escapeShellArg v}") aliases
            );
          };
          ".config/zsh/.zshenv" = {
            text =
              exportVars
              + ''

                export TERMINAL="${defaults.terminal}"
                export BROWSER="${defaults.browser}"
                export EDITOR="${defaults.editor}"
              '';
          };
          ".config/zsh/.zshrc" = {
            text = lib.concatStringsSep "\n" (
              [
                "source \"$ZDOTDIR/aliases.zsh\""
              ]
              ++ lib.optional (zellij.enable && zellij.autoStart) "source \"$ZDOTDIR/zellij.zsh\""
              ++ [
                pluginSettings
                historySettings
                completionSettings
                promptSettings
                tempPkgFunction
                tempRunFunction
                fanSpeedFunction
              ]
            );
          };
        }
        // lib.optionalAttrs (zellij.enable && zellij.autoStart) {
          ".config/zsh/zellij.zsh" = {
            text = zellijStartup;
          };
        };
    };
  };
}
