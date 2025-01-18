#===============================================================================
#                      🐚 Zsh Shell Configuration 🐚
#===============================================================================
# 🌍 Environment variables
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

    #── 🌍 Environment Settings ────────────────#
    # IN ENV.NIX!

    #── 📝 Profile Configuration ──────────────#
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
         Hyprland
      fi
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
    '';

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

    #── 🔗 Shell Aliases ──────────────────#
    shellAliases = {
      #── 📱 XDG Compliance ────────────────#
      adb = "HOME=\"$XDG_DATA_HOME/android\" adb";
      wget = "wget --hsts-file=\"$XDG_DATA_HOME/wget-hsts\"";
      svn = "svn --config-dir \"$XDG_CONFIG_HOME/subversion\"";
      yarn = "yarn --use-yarnrc \"$XDG_CONFIG_HOME/yarn/config\"";
      mocp = "mocp -M \"$XDG_CONFIG_HOME/moc\" -O MOCDir=\"$XDG_CONFIG_HOME/moc\"";

      #── 📝 Text Editor Aliases ───────────#
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

      #── 🔄 System Maintenance ────────────#
      dotlink = "$HOME/dotfiles/scripts/dotlink.sh";
      dotsync = "$HOME/dotfiles/scripts/dotsync.sh";
      dotpush = "$HOME/dotfiles/scripts/dotsync.sh push";

      #── 🎵 Music Tools ──────────────────#
      ytm4a = "$HOME/scripts/ytm4a.sh";
      spotm4a = "$HOME/scripts/spotm4a.py";

      #── 📦 Package Management ───────────#
      pkgs = "paru -Qq | grep";
      orphans = "pacman -Qttdq";
      pacfix = "sudo rm /var/lib/pacman/db.lck";
      filecheck = "paru -Qkk 2>&1 | grep -v \"0 altered files\"";

      #── 🛠️ Utility Aliases ─────────────#
      userctl = "systemctl --user";
      ooba = "/home/y0usaf/text-generation-webui/start_linux.sh";
      "nvidia-settings" = "nvidia-settings --config=\"$XDG_CONFIG_HOME\"/nvidia/settings";
      esrgan = "realesrgan-ncnn-vulkan -i ~/Pictures/Upscale/Input -o ~/Pictures/Upscale/Output";

      #── 📁 Directory Listing ───────────#
      "l." = "lsd -A | grep -E \"^\\.\"";
      la = "lsd -A --color=always --group-dirs=first --icon=always";
      ll = "lsd -l --color=always --group-dirs=first --icon=always";
      ls = "lsd -lA --color=always --group-dirs=first --icon=always";
      lt = "lsd -A --tree --color=always --group-dirs=first --icon=always";

      #── 🔍 Search Tools ───────────────#
      grep = "grep --color=auto";
      dir = "dir --color=auto";
      egrep = "grep -E --color=auto";
      fgrep = "grep -F --color=auto";

      #── 🌐 Network Tools ──────────────#
      tailup = "sudo tailscale up";
      taildown = "sudo tailscale down";

      #── 🎥 Media Tools ───────────────#
      compressvid = "~/dotfiles/scripts/compressvid.sh";
    };
  };
}
