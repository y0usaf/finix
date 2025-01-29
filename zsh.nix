#===============================================================================
#                      🐚 Zsh Shell Configuration 🐚
#===============================================================================
# 🌍 Environment variables (see env.nix)
# 📝 Shell aliases
# 🔧 Profile settings
# 📜 History configuration
# 🖥️ Host-specific functions
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

    #── 📜 History Settings ─────────────────#
    history = {
      size = 1000;
      save = 1000;
      path = "$HOME/.local/state/zsh/history";
      ignoreDups = true;
      expireDuplicatesFirst = true;
      share = true;
      extended = true;
    };

    #── 🔧 Profile Configuration ──────────────#
    profileExtra = ''
      # Hardware-specific settings
      case "$(hostname)" in
        "y0usaf-desktop")
          sudo nvidia-smi -pl 150
          ${lib.optionalString globals.enableHyprland "Hyprland"}
          ;;
        "y0usaf-laptop")
          ${lib.optionalString globals.enableHyprland "Hyprland"}
          ;;
      esac
    '';

    #── 🔧 Shell Initialization ──────────────#
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

      # Temporarily add a Nix package to shell
      temppkg() {
        if [ -z "$1" ]; then
          echo "Usage: temppkg package_name"
          return 1
        fi
        nix-shell -p "$1" --run "exec $SHELL"
      }
    '';

    #── 🔗 Shell Aliases ──────────────────#
    shellAliases = {
      #── 📱 XDG Compliance ────────────────#
      adb = "HOME=\"$XDG_DATA_HOME/android\" adb";
      wget = "wget --hsts-file=\"$XDG_DATA_HOME/wget-hsts\"";
      svn = "svn --config-dir \"$XDG_CONFIG_HOME/subversion\"";
      yarn = "yarn --use-yarnrc \"$XDG_CONFIG_HOME/yarn/config\"";
      mocp = "mocp -M \"$XDG_CONFIG_HOME/moc\" -O MOCDir=\"$XDG_CONFIG_HOME/moc\"";

      #── 📝 Config Editing ────────────────#
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

      #── 🔄 System Management ─────────────#
      dotlink = "$HOME/dotfiles/scripts/dotlink.sh";
      dotsync = "$HOME/dotfiles/scripts/dotsync.sh";
      dotpush = "$HOME/dotfiles/scripts/dotsync.sh push";
      userctl = "systemctl --user";
      hmfail = "journalctl -u home-manager-y0usaf.service -n 20 --no-pager";
      pkgs = "nix-store --query --requisites /run/current-system | cut -d- -f2- | sort | uniq | grep -i";
      pkgcount = "nix-store --query --requisites /run/current-system | cut -d- -f2- | sort | uniq | wc -l";

      #── 🎵 Media & Tools ─────────────────#
      ytm4a = "$HOME/scripts/ytm4a.sh";
      spotm4a = "$HOME/scripts/spotm4a.py";
      compressvid = "~/dotfiles/scripts/compressvid.sh";
      ooba = "/home/y0usaf/text-generation-webui/start_linux.sh";
      "nvidia-settings" = "nvidia-settings --config=\"$XDG_CONFIG_HOME\"/nvidia/settings";
      esrgan = "realesrgan-ncnn-vulkan -i ~/Pictures/Upscale/Input -o ~/Pictures/Upscale/Output";

      #── 📁 Directory & Search ───────────#
      "l." = "lsd -A | grep -E \"^\\.\"";
      la = "lsd -A --color=always --group-dirs=first --icon=always";
      ll = "lsd -l --color=always --group-dirs=first --icon=always";
      ls = "lsd -lA --color=always --group-dirs=first --icon=always";
      lt = "lsd -A --tree --color=always --group-dirs=first --icon=always";
      grep = "grep --color=auto";
      dir = "dir --color=auto";
      egrep = "grep -E --color=auto";
      fgrep = "grep -F --color=auto";

      #── 🌐 Network Tools ──────────────#
      tailup = "sudo tailscale up";
      taildown = "sudo tailscale down";

      #── 🌐 Network Tools ──────────────#
      "checkportals" = ''
        echo "🔍 Checking XDG Portal Logs..." && \
        journalctl -b | grep -iE "(xdg.*portal|portal.*xdg|portals|xdg-desktop-portal)" | \
        while IFS= read -r line; do
          echo "📋 $line"
        done || echo "❌ No portal logs found"
      '';
    };
  };
}
