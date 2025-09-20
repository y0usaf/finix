{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.shell.zsh;
  inherit (config.user) name homeDirectory tokensDirectory;
  zshConfig = {
    cat-fetch = true;
    history-memory = 10000;
    history-storage = 10000;
    enableFancyPrompt = true;
    zellij = {
      enable = false;
    };
  };
in {
  options.home.shell.zsh = {
    enable = lib.mkEnableOption "zsh shell configuration";
  };
  config = lib.mkIf cfg.enable {
    environment.variables.ZDOTDIR = "${config.user.configDirectory}/zsh";
    programs.zsh.enable = true;

    environment.systemPackages = with pkgs; [
      zsh
      bat
      lsd
      tree
    ];

    hjem.users.${name} = {
      files = {
        ".config/zsh/.zshenv" = {
          text = let
            tokenFunctionScript = ''
              export_vars_from_files() {
                  local dir_path=$1

                  local skip_for_opencode=("ANTHROPIC_API_KEY" "OPENAI_API_KEY")

                  for file_path in "$dir_path"
                      if [[ -f $file_path ]]; then
                          var_name=$(basename "$file_path" .txt)


                          if [[ " ''${skip_for_opencode[@]} " =~ " $var_name " ]]; then
                              continue
                          fi

                          export $var_name=$(cat "$file_path")
                      fi
                  done
              }
              export_vars_from_files "${tokensDirectory}"


              export TERMINAL="${config.home.core.defaults.terminal}"
              export BROWSER="${config.home.core.defaults.browser}"
              export EDITOR="${config.home.core.defaults.editor}"
            '';
          in
            tokenFunctionScript;
          clobber = true;
        };
        ".config/zsh/.zprofile" = {
          text = ''
            if [[ $- == *i* ]]; then
              case "$(hostname)" in
                "${config.user.name}-desktop")
                  sudo nvidia-smi -pl 150
                  ;;
                "${config.user.name}-laptop")
                  ;;
              esac
            fi
          '';
          clobber = true;
        };
        ".config/zsh/.zshrc" = {
          text = ''

            export TERMINAL="${config.home.core.defaults.terminal}"
            export BROWSER="${config.home.core.defaults.browser}"
            export EDITOR="${config.home.core.defaults.editor}"


            for alias_file in ''${ZDOTDIR:-$XDG_CONFIG_HOME/zsh}/aliases
              source "$alias_file"
            done

            HISTSIZE=${toString zshConfig.history-memory}
            SAVEHIST=${toString zshConfig.history-storage}
             HISTFILE="${homeDirectory}/.local/state/zsh/history"
            setopt HIST_IGNORE_DUPS
            setopt HIST_IGNORE_ALL_DUPS
            setopt HIST_IGNORE_SPACE
            setopt HIST_EXPIRE_DUPS_FIRST
            setopt SHARE_HISTORY
            setopt EXTENDED_HISTORY
            ${lib.optionalString zshConfig.enableFancyPrompt ''
              PS1='%F{blue}%~ %(?.%F{green}.%F{red})%#%f '
            ''}
            zstyle ':completion:*' menu select
            zstyle ':completion:*' matcher-list \
                'm:{a-zA-Z}={A-Za-z}' \
                'r:|[._-]=* r:|=*' \
                'l:|=* r:|=*'
            if [ "$(hostname)" = "${config.user.name}-laptop" ]; then
                fanspeed() {
                    if [ -z "$1" ]; then
                        echo "Usage: fanspeed <percentage>"
                        return 1
                    fi
                    local speed="$1"
                    asusctl fan-curve -m quiet -D "30c:$speed,40c:$speed,50c:$speed,60c:$speed,70c:$speed,80c:$speed,90c:$speed,100c:$speed" -e true -f gpu
                    asusctl fan-curve -m quiet -D "30c:$speed,40c:$speed,50c:$speed,60c:$speed,70c:$speed,80c:$speed,90c:$speed,100c:$speed" -e true -f cpu
                }
            fi
            temppkg() {
                if [ -z "$1" ]; then
                    echo "Usage: temppkg package_name"
                    return 1
                fi
                nix-shell -p "$1" --run "exec $SHELL"
            }
            temprun() {
                if [ -z "$1" ]; then
                    echo "Usage: temprun package_name [args...]"
                    return 1
                fi
                local pkg="$1"
                shift
                nix run "nixpkgs#$pkg" -- "$@"
            }
          '';
          clobber = true;
        };
      };
    };
  };
}
