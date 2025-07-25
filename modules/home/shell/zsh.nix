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
    users.users.${name}.maid = {
      packages = with pkgs; [
        zsh
        bat
        lsd
        tree
      ];
      file.home = {
        ".config/zsh/.zshenv".text = let
          tokenFunctionScript = ''
            export_vars_from_files() {
                local dir_path=$1
                # Skip opencode-related API keys to prefer oauth
                local skip_for_opencode=("ANTHROPIC_API_KEY" "OPENAI_API_KEY")

                for file_path in "$dir_path"/*.txt; do
                    if [[ -f $file_path ]]; then
                        var_name=$(basename "$file_path" .txt)

                        # Skip API keys that conflict with opencode oauth
                        if [[ " ''${skip_for_opencode[@]} " =~ " $var_name " ]]; then
                            continue
                        fi

                        export $var_name=$(cat "$file_path")
                    fi
                done
            }
            export_vars_from_files "${tokensDirectory}"
          '';
        in
          tokenFunctionScript;
        ".config/zsh/.zprofile".text = ''
          if [[ $- == *i* ]]; then
            case "$(hostname)" in
              "${config.user.name}-desktop")
                sudo nvidia-smi -pl 150
                if [ "$(tty)" = "/dev/tty1" ]; then
                  Hyprland
                fi
                ;;
              "${config.user.name}-laptop")
                if [ "$(tty)" = "/dev/tty1" ]; then
                  Hyprland
                fi
                ;;
            esac
          fi
        '';
        ".config/zsh/.zshrc".text = let
          baseAliases = {
            adb = "HOME=\"$XDG_DATA_HOME/android\" adb";
            wget = "wget --hsts-file=\"$XDG_DATA_HOME/wget-hsts\"";
            svn = "svn --config-dir \"$XDG_CONFIG_HOME/subversion\"";
            yarn = "yarn --use-yarnrc \"$XDG_CONFIG_HOME/yarn/config\"";
            mocp = "mocp -M \"$XDG_CONFIG_HOME/moc\" -O MOCDir=\"$XDG_CONFIG_HOME/moc\"";
            cat = "bat";
            cattree = "${config.user.nixosConfigDirectory}/lib/scripts/cattree.sh";
            userctl = "systemctl --user";
            hmfail = "journalctl -u home-manager-${name}.service -n 20 --no-pager";
            pkgs = "nix-store --query --requisites /run/current-system | cut -d- -f2- | sort | uniq | grep -i";
            pkgcount = "nix-store --query --requisites /run/current-system | cut -d- -f2- | sort | uniq | wc -l";
            hwconfig = "sudo nixos-generate-config --show-hardware-config";
            esrgan = "realesrgan-ncnn-vulkan -i ${homeDirectory}/Pictures/Upscale/Input -o ${homeDirectory}/Pictures/Upscale/Output";
            "l." = "lsd -A | grep -E \"^\\.\"";
            la = "lsd -A --color=always --group-dirs=first --icon=always";
            ll = "lsd -l --color=always --group-dirs=first --icon=always";
            ls = "lsd -lA --color=always --group-dirs=first --icon=always";
            lt = "lsd -A --tree --color=always --group-dirs=first --icon=always";
            grep = "grep --color=auto";
            dir = "dir --color=auto";
            egrep = "grep -E --color=auto";
            fgrep = "grep -F --color=auto";
            "hmpush" = "git -C ${config.user.nixosConfigDirectory} push origin main --force";
            "hmpull" = "git -C ${config.user.nixosConfigDirectory} fetch origin && git -C ${config.user.nixosConfigDirectory} reset --hard origin/main";
            gpupower = "sudo nvidia-smi -pl";
            lintcheck = "clear; statix check .; deadnix .";
            lintfix = "clear; statix fix .; deadnix .";
            ide = "zellij --layout ${config.user.configDirectory}/zellij/layouts/ide.kdl";
            opencode = "${homeDirectory}/.npm-global/bin/opencode";
          };
        in ''
          HISTSIZE=${toString zshConfig.history-memory}
          SAVEHIST=${toString zshConfig.history-storage}
           HISTFILE="${homeDirectory}/.local/state/zsh/history"          setopt HIST_IGNORE_DUPS
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

          ${lib.concatStringsSep "\n"
            (lib.mapAttrsToList (name: value: "alias ${name}='${value}'") baseAliases)}
        '';
      };
    };
  };
}
