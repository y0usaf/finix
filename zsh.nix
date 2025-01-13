#===============================================================================
#
#                     Zsh Shell Configuration
#
# Description:
#     Configuration file for the Zsh shell environment. Includes:
#     - Environment variables
#     - Shell aliases
#     - Profile configurations
#     - History settings
#     - Host-specific functions
#
# Author: y0usaf
# Last Modified: 2025
#
#===============================================================================
{
  config,
  pkgs,
  lib,
  globals,
  ...
}: {
  programs.zsh = {
    enable = true;

    #===========================================================================
    #
    #                               ZSHENV
    #
    #===========================================================================

    #===========================================================================
    #
    #                               ZPROFILE
    #
    #===========================================================================
    profileExtra = ''
      # Start SSH agent
      eval "$(ssh-agent -s)"

      if [ -f /home/y0usaf/Tokens/id_rsa_y0usaf ]; then
          ssh-add ~/Tokens/id_rsa_y0usaf
      fi

      if [ "$(hostname)" = "y0usaf-desktop" ]; then
          sudo nvidia-smi -pl 150
          Hyprland
      elif [ "$(hostname)" = "y0usaf-laptop" ]; then
          Sysup &
          Hyprland
      fi
    '';

    #===========================================================================
    #
    #                               ZSHRC
    #
    #===========================================================================
    initExtra = ''
      # Launch fetch
      nitch

      # Set up the basic prompt
      PS1='%F{blue}%~ %(?.%F{green}.%F{red})%#%f '

      # Enable advanced tab completion
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

      # Host-specific functions and aliases
      if [ "$(hostname)" = "y0usaf-desktop" ]; then
          alias gpupower='sudo nvidia-smi -pl'
      elif [ "$(hostname)" = "y0usaf-laptop" ]; then
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

      # Complex alias for dependency count
      alias depcount='{
          for pkg in $(pacman -Qq); do
              dep_count=$(pactree -u "$pkg" | wc -l);
              echo "$pkg $dep_count";
          done | sort -nk2 -r
      } && echo "Dependency count completed successfully" || echo "An error occurred."'

      # NixOS management function
      function nh-os {
        if [ "$1" = "switch" ]; then
          git -C ~/nixos add . && \
          alejandra ~/nixos && \
          if nh os switch ~/nixos; then
            if ! git -C ~/nixos diff --quiet origin/main; then
              git -C ~/nixos commit -m "auto: system update $(date '+%Y-%m-%d %H:%M:%S')" && \
              git -C ~/nixos push -f origin main
            fi
          fi
        elif [ "$1" = "build" ]; then
          alejandra ~/nixos && \
          nh os build ~/nixos
        else
          echo "Usage: nh-os [switch|build]"
          return 1
        fi
      }
    '';

    history = {
      size = 1000;
      save = 1000;
      path = "$HOME/.local/state/zsh/history";
      ignoreDups = true;
      expireDuplicatesFirst = true;
      share = true;
      extended = true;
    };

    shellAliases = {
      adb = "HOME=\"$XDG_DATA_HOME/android\" adb";
      wget = "wget --hsts-file=\"$XDG_DATA_HOME/wget-hsts\"";
      svn = "svn --config-dir $XDG_CONFIG_HOME/subversion";
      yarn = "yarn --use-yarnrc $XDG_CONFIG_HOME/yarn/config";
      mocp = "mocp -M \"$XDG_CONFIG_HOME/moc\" -O MOCDir=\"$XDG_CONFIG_HOME/moc\"";
      "nh-os" = ''
        git -C ~/nixos add . && \
        alejandra ~/nixos && \
      '';

      # Switch subcommand
      "nh-os switch" = ''
        git -C ~/nixos add . && \
        alejandra ~/nixos && \
        if nh os switch ~/nixos; then
          if ! git -C ~/nixos diff --quiet origin/main; then
            git -C ~/nixos commit -m "auto: system update $(date '+%Y-%m-%d %H:%M:%S')" && \
            git -C ~/nixos push -f origin main
          fi
        fi
      '';

      # Build subcommand
      "nh-os build" = ''
        alejandra ~/nixos && \
        nh os build ~/nixos
      '';

      # Text Editor Aliases
      aliases = "nvim $HOME/dotfiles/.config/zsh/aliases";
      agscfg = "nvim $HOME/dotfiles/.config/ags/config.js";
      swaycfg = "nvim $HOME/dotfiles/.config/sway/*";
      footcfg = "nvim $HOME/dotfiles/.config/foot/foot.ini";
      hyprcfg = "nvim $HOME/dotfiles/.config/hypr/hyprland.conf";
      cavacfg = "nvim $HOME/dotfiles/.config/cava/config";
      zshrc = "nvim $HOME/dotfiles/.config/zsh/.zshrc";
      zshenv = "nvim $HOME/dotfiles/.config/zsh/.zshenv";
      zprofile = "nvim $HOME/dotfiles/.config/zsh/.zprofile";
      waybarcfg = "nvim $HOME/dotfiles/.config/waybar/config";
      waybarcss = "nvim $HOME/dotfiles/.config/waybar/style.css";
      fontconfig = "nvim $HOME/dotfiles/.config/fontconfig/fonts.conf";
      scripts = "nvim $HOME/dotfiles/scripts/";
      zshistory = "nvim $XDG_CONFIG_HOME/zsh/.zsh_history";
      gitignore = "nvim $HOME/.gitignore";

      # System Maintenance Aliases
      dotlink = "$HOME/dotfiles/scripts/dotlink.sh";
      dotsync = "$HOME/dotfiles/scripts/dotsync.sh";
      dotpull = "$HOME/dotfiles/scripts/dotsync.sh pull";
      dotpush = "$HOME/dotfiles/scripts/dotsync.sh push";
      sysup = let
        repoUrl = globals.homeManagerRepoUrl;
      in ''
        # Initialize git if needed
        if [ ! -d ~/nixos/.git ]; then
          git -C ~/nixos init && \
          git -C ~/nixos branch -M main && \
          git -C ~/nixos remote add origin "${repoUrl}"
        fi && \

        # Main update process
        git -C ~/nixos add . && \
        alejandra ~/nixos >/dev/null 2>&1 && \
        if nh os switch ~/nixos; then
          if ! git -C ~/nixos diff --quiet origin/main; then
            git -C ~/nixos commit -m "auto: system update $(date '+%Y-%m-%d %H:%M:%S')" && \
            git -C ~/nixos push -f origin main
          fi
        fi
      '';

      # Build without switching
      sysbuild = "alejandra ~/nixos >/dev/null 2>&1 && nh os build ~/nixos";

      # Music Downloading Aliases
      ytm4a = "$HOME/scripts/ytm4a.sh";
      spotm4a = "$HOME/scripts/spotm4a.py";

      # Package Management Aliases
      pkgs = "paru -Qq | grep";
      orphans = "pacman -Qttdq";
      pacfix = "sudo rm /var/lib/pacman/db.lck";
      filecheck = "paru -Qkk 2>&1 | grep -v \"0 altered files\"";

      # Utility Aliases
      userctl = "systemctl --user";
      ooba = "/home/y0usaf/text-generation-webui/start_linux.sh";
      "nvidia-settings" = "nvidia-settings --config=\"$XDG_CONFIG_HOME\"/nvidia/settings";
      esrgan = "realesrgan-ncnn-vulkan -i ~/Pictures/Upscale/Input -o ~/Pictures/Upscale/Output";

      # Directory Listing Aliases
      "l." = "lsd -A | grep -E \"^\\.\"";
      la = "lsd -A --color=always --group-dirs=first --icon=always";
      ll = "lsd -l --color=always --group-dirs=first --icon=always";
      ls = "lsd -lA --color=always --group-dirs=first --icon=always";
      lt = "lsd -A --tree --color=always --group-dirs=first --icon=always";

      # Grep and Dir Aliases
      grep = "grep --color=auto";
      dir = "dir --color=auto";
      egrep = "grep -E --color=auto";
      fgrep = "grep -F --color=auto";

      # Network Aliases
      tailup = "sudo tailscale up";
      taildown = "sudo tailscale down";

      # Miscellaneous
      compressvid = "~/dotfiles/scripts/compressvid.sh";
    };
  };
}
