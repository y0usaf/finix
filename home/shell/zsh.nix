{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.shell.zsh;
  username = "y0usaf";
  homeDirectory = "/home/y0usaf";
  tokenDir = "/home/y0usaf/Tokens";
  xdgConfigHome = "${homeDirectory}/.config";
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
    environment.variables.ZDOTDIR = "$HOME/.config/zsh";
    programs.zsh.enable = true;
    users.users.${username}.maid = {
      packages = with pkgs; [
        zsh
        bat
        lsd
        tree
      ];
      file.home = {
        ".config/zsh/.zshenv".text = let
          inherit tokenDir;
          tokenFunctionScript = ''
            export_vars_from_files() {
                local dir_path=$1
                for file_path in "$dir_path"/*.txt; do
                    if [[ -f $file_path ]]; then
                        var_name=$(basename "$file_path" .txt)
                        export $var_name=$(cat "$file_path")
                    fi
                done
            }
            export_vars_from_files "${tokenDir}"
          '';
        in
          tokenFunctionScript;
        ".config/zsh/.zprofile".text = ''
          if [[ $- == *i* ]]; then
            case "$(hostname)" in
              "y0usaf-desktop")
                sudo nvidia-smi -pl 150
                if [ "$(tty)" = "/dev/tty1" ]; then
                  Hyprland
                fi
                ;;
              "y0usaf-laptop")
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
            cattree = "$HOME/nixos/lib/resources/scripts/cattree.sh";
            userctl = "systemctl --user";
            hmfail = "journalctl -u home-manager-y0usaf.service -n 20 --no-pager";
            pkgs = "nix-store --query --requisites /run/current-system | cut -d- -f2- | sort | uniq | grep -i";
            pkgcount = "nix-store --query --requisites /run/current-system | cut -d- -f2- | sort | uniq | wc -l";
            hwconfig = "sudo nixos-generate-config --show-hardware-config";
            esrgan = "realesrgan-ncnn-vulkan -i ~/Pictures/Upscale/Input -o ~/Pictures/Upscale/Output";
            "l." = "lsd -A | grep -E \"^\\.\"";
            la = "lsd -A --color=always --group-dirs=first --icon=always";
            ll = "lsd -l --color=always --group-dirs=first --icon=always";
            ls = "lsd -lA --color=always --group-dirs=first --icon=always";
            lt = "lsd -A --tree --color=always --group-dirs=first --icon=always";
            grep = "grep --color=auto";
            dir = "dir --color=auto";
            egrep = "grep -E --color=auto";
            fgrep = "grep -F --color=auto";
            "hmpush" = "git -C ~/nixos push origin main --force";
            "hmpull" = "git -C ~/nixos fetch origin && git -C ~/nixos reset --hard origin/main";
            gpupower = "sudo nvidia-smi -pl";
            lintcheck = "clear; statix check .; deadnix .";
            lintfix = "clear; statix fix .; deadnix .";
            ide = "zellij --layout ~/.config/zellij/layouts/ide.kdl";
          };
        in ''
          HISTSIZE=${toString zshConfig.history-memory}
          SAVEHIST=${toString zshConfig.history-storage}
          HISTFILE="$HOME/.local/state/zsh/history"
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
          if [ "$(hostname)" = "y0usaf-laptop" ]; then
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
