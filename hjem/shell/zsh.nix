#===============================================================================
# 🐚 Zsh Shell Configuration Module for Hjem 🐚
# Configures the Z shell with custom settings and functionality
# - Shell history management
# - Hardware-specific profile settings
# - Custom functions and aliases
# - Prompt and completion configuration
#===============================================================================
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.cfg.hjome.shell.zsh;
  # Get shared user preferences
  sharedZsh = config.cfg.shared.zsh;
in {
  #===========================================================================
  # Module Options
  #===========================================================================
  options.cfg.hjome.shell.zsh = {
    enable = lib.mkEnableOption "zsh shell configuration";
    enableFancyPrompt = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the custom PS1 prompt";
    };
  };

  #===========================================================================
  # Module Configuration
  #===========================================================================
  config = lib.mkIf cfg.enable {
    #=========================================================================
    # Packages
    #=========================================================================
    packages = with pkgs; [
      zsh
      bat
      lsd
      tree
    ];

    #=========================================================================
    # Declare Zsh Files
    #=========================================================================
    fileRegistry.declare = {
      zshenv = {
        filename = ".zshenv";
        baseContent = let
          # Get the token directory path from shared config
          inherit (config.cfg.shared) tokenDir;
          # Token management function (from original envExtra)
          tokenFunctionScript = ''
            # Token management function
            export_vars_from_files() {
                local dir_path=$1
                for file_path in "$dir_path"/*.txt; do
                    if [[ -f $file_path ]]; then
                        var_name=$(basename "$file_path" .txt)
                        export $var_name=$(cat "$file_path")
                    fi
                done
            }

            # Export tokens using the configured directory
            export_vars_from_files "${tokenDir}"
          '';
        in tokenFunctionScript;
      };
      
      zprofile = {
        filename = ".zprofile";
        baseContent = ''
          # Hardware-specific settings based on hostname.
          case "$(hostname)" in
            "y0usaf-desktop")
              sudo nvidia-smi -pl 150
              # Only launch Hyprland if we're in a TTY
              if [ "$(tty)" = "/dev/tty1" ]; then
                Hyprland
              fi
              ;;
            "y0usaf-laptop")
              # Only launch Hyprland if we're in a TTY
              if [ "$(tty)" = "/dev/tty1" ]; then
                Hyprland
              fi
              ;;
          esac
        '';
      };
      
      zshrc = {
        filename = ".zshrc";
        baseContent = ''
          # History configuration
          HISTSIZE=${toString sharedZsh.history-memory}
          SAVEHIST=${toString sharedZsh.history-storage}
          HISTFILE="$HOME/.local/state/zsh/history"
          setopt HIST_IGNORE_DUPS
          setopt HIST_IGNORE_ALL_DUPS
          setopt HIST_IGNORE_SPACE
          setopt HIST_EXPIRE_DUPS_FIRST
          setopt SHARE_HISTORY
          setopt EXTENDED_HISTORY

          ${lib.optionalString sharedZsh.cat-fetch ''
            # ----------------------------
            # Function: print_cats
            # ----------------------------
            # Prints a colorful array of cats to the terminal.
            print_cats() {
                echo -e "\033[0;31m ⟋|､      \033[0;34m  ⟋|､      \033[0;35m  ⟋|､      \033[0;32m  ⟋|､
            \033[0;31m(°､ ｡ 7    \033[0;34m(°､ ｡ 7    \033[0;35m(°､ ｡ 7    \033[0;32m(°､ ｡ 7
            \033[0;31m |､  ~ヽ   \033[0;34m |､  ~ヽ   \033[0;35m |､  ~ヽ   \033[0;32m |､  ~ヽ
            \033[0;31m じしf_,)〳\033[0;34m じしf_,)〳\033[0;35m じしf_,)〳\033[0;32m じしf_,)〳
            \033[0;36m  [tomo]   \033[0;33m  [moon]   \033[0;32m  [ekko]   \033[0;35m  [bozo]\033[0m"
            }

            # Immediately print the cats on startup.
            print_cats
          ''}

          ${lib.optionalString cfg.enableFancyPrompt ''
            # ----------------------------
            # Prompt Setup
            # ----------------------------
            PS1='%F{blue}%~ %(?.%F{green}.%F{red})%#%f '
          ''}

          # ----------------------------
          # Advanced Tab Completion
          # ----------------------------
          zstyle ':completion:*' menu select
          zstyle ':completion:*' matcher-list \
              'm:{a-zA-Z}={A-Za-z}' \
              'r:|[._-]=* r:|=*' \
              'l:|=* r:|=*'

          # ----------------------------
          # Host-specific Functions
          # ----------------------------
          # Define a "fanspeed" function only when running on the laptop.
          if [ "$(hostname)" = "y0usaf-laptop" ]; then
              fanspeed() {
                  if [ -z "$1" ]; then
                      echo "Usage: fanspeed <percentage>"
                      return 1
                  fi
                  local speed="$1"
                  # Configure fan curves for both GPU and CPU.
                  asusctl fan-curve -m quiet -D "30c:$speed,40c:$speed,50c:$speed,60c:$speed,70c:$speed,80c:$speed,90c:$speed,100c:$speed" -e true -f gpu
                  asusctl fan-curve -m quiet -D "30c:$speed,40c:$speed,50c:$speed,60c:$speed,70c:$speed,80c:$speed,90c:$speed,100c:$speed" -e true -f cpu
              }
          fi

          # ----------------------------
          # Function: temppkg
          # ----------------------------
          # Temporarily adds a Nix package to the shell.
          temppkg() {
              if [ -z "$1" ]; then
                  echo "Usage: temppkg package_name"
                  return 1
              fi
              nix-shell -p "$1" --run "exec $SHELL"
          }

          # ----------------------------
          # Function: temprun
          # ----------------------------
          # Temporarily runs a Nix package without installing it.
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
      };
    };

    #=========================================================================
    # Add Shell Aliases
    #=========================================================================
    fileRegistry.content.zshrc.aliases = let
      baseAliases = {
        #----- XDG Compliance Shortcuts -----
        adb = "HOME=\"$XDG_DATA_HOME/android\" adb";
        wget = "wget --hsts-file=\"$XDG_DATA_HOME/wget-hsts\"";
        svn = "svn --config-dir \"$XDG_CONFIG_HOME/subversion\"";
        yarn = "yarn --use-yarnrc \"$XDG_CONFIG_HOME/yarn/config\"";
        mocp = "mocp -M \"$XDG_CONFIG_HOME/moc\" -O MOCDir=\"$XDG_CONFIG_HOME/moc\"";
        cat = "bat";

        #----- Custom Scripts -----
        cattree = "$HOME/nixos/lib/resources/scripts/cattree.sh";

        #----- System Management Shortcuts -----
        userctl = "systemctl --user";
        hmfail = "journalctl -u home-manager-y0usaf.service -n 20 --no-pager";
        pkgs = "nix-store --query --requisites /run/current-system | cut -d- -f2- | sort | uniq | grep -i";
        pkgcount = "nix-store --query --requisites /run/current-system | cut -d- -f2- | sort | uniq | wc -l";
        hwconfig = "sudo nixos-generate-config --show-hardware-config";

        #----- Media & Tools Shortcuts -----
        esrgan = "realesrgan-ncnn-vulkan -i ~/Pictures/Upscale/Input -o ~/Pictures/Upscale/Output";

        #----- Directory & Search Shortcuts -----
        "l." = "lsd -A | grep -E \"^\\.\"";
        la = "lsd -A --color=always --group-dirs=first --icon=always";
        ll = "lsd -l --color=always --group-dirs=first --icon=always";
        ls = "lsd -lA --color=always --group-dirs=first --icon=always";
        lt = "lsd -A --tree --color=always --group-dirs=first --icon=always";
        grep = "grep --color=auto";
        dir = "dir --color=auto";
        egrep = "grep -E --color=auto";
        fgrep = "grep -F --color=auto";

        #----- Home Manager Repo Aliases -----
        "hmpush" = "git -C ~/nixos push origin main --force";
        "hmpull" = "git -C ~/nixos fetch origin && git -C ~/nixos reset --hard origin/main";

        #----- Hardware Management Shortcut -----
        gpupower = "sudo nvidia-smi -pl";
      };

      # Note: Kitty Panel aliases disabled until kittens module is available
      kittyAliases = {};

      allAliases = baseAliases // kittyAliases;
    in lib.concatStringsSep "\n" 
      (lib.mapAttrsToList (name: value: "alias ${name}='${value}'") allAliases);
  };
}