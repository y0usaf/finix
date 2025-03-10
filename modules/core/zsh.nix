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
  profile,
  ...
}: {
  # Add bat package to the system
  home.packages = with pkgs; [
    bat
    lsd
    tree
  ];

  programs.zsh = {
    enable = true;

    #===========================================================================
    # Zsh Shell Configuration
    #===========================================================================

    #---------------------------------------------------------------------------
    # History Settings: Configure shell history behavior.
    #---------------------------------------------------------------------------
    history = {
      size = 1000;
      save = 1000;
      path = "$HOME/.local/state/zsh/history";
      ignoreDups = true;
      expireDuplicatesFirst = true;
      share = true;
      extended = true;
    };

    #---------------------------------------------------------------------------
    # Profile Settings: Hardware-specific and feature-based extra commands.
    #---------------------------------------------------------------------------
    profileExtra = ''
      # Hardware-specific settings based on hostname.
      case "$(hostname)" in
        "y0usaf-desktop")
          sudo nvidia-smi -pl 150
          # Only launch Hyprland if we're in a TTY and the feature is enabled
          if [ "$(tty)" = "/dev/tty1" ] && ${lib.optionalString (builtins.elem "hyprland" profile.features) "true"}; then
            Hyprland
          fi
          ;;
        "y0usaf-laptop")
          # Only launch Hyprland if we're in a TTY and the feature is enabled
          if [ "$(tty)" = "/dev/tty1" ] && ${lib.optionalString (builtins.elem "hyprland" profile.features) "true"}; then
            Hyprland
          fi
          ;;
      esac
    '';

    #---------------------------------------------------------------------------
    # Shell Initialization: Define functions, prompt, and additional settings.
    #---------------------------------------------------------------------------
    initExtra = ''
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

      # ----------------------------
      # Function: cattree
      # ----------------------------
      # Display file contents using find and bat, recursively showing all files including symlinks
      cattree() {
          local target
          if [ -z "$1" ]; then
              target="$(pwd)"
          else
              target="$1"
          fi

          find "$target" \( -type f -o -type l \) -not -path "*/\.*" | sort | while read -r file; do
              echo "File: $file"
              bat "$file"
              echo ""
          done
      }

      # ----------------------------
      # Prompt Setup
      # ----------------------------
      PS1='%F{blue}%~ %(?.%F{green}.%F{red})%#%f '

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
    '';

    #---------------------------------------------------------------------------
    # Shell Aliases: Define shortcuts for common commands.
    #---------------------------------------------------------------------------
    shellAliases = {
      #----- XDG Compliance Shortcuts -----
      adb = "HOME=\"$XDG_DATA_HOME/android\" adb";
      wget = "wget --hsts-file=\"$XDG_DATA_HOME/wget-hsts\"";
      svn = "svn --config-dir \"$XDG_CONFIG_HOME/subversion\"";
      yarn = "yarn --use-yarnrc \"$XDG_CONFIG_HOME/yarn/config\"";
      mocp = "mocp -M \"$XDG_CONFIG_HOME/moc\" -O MOCDir=\"$XDG_CONFIG_HOME/moc\"";
      cat = "bat";

      #----- System Management Shortcuts -----
      userctl = "systemctl --user";
      hmfail = "journalctl -u home-manager-y0usaf.service -n 20 --no-pager";
      pkgs = "nix-store --query --requisites /run/current-system | cut -d- -f2- | sort | uniq | grep -i";
      pkgcount = "nix-store --query --requisites /run/current-system | cut -d- -f2- | sort | uniq | wc -l";
      hwconfig = "sudo nixos-generate-config --show-hardware-config";

      #----- Media & Tools Shortcuts -----
      esrgan = "realesrgan-ncnn-vulkan -i ~/Pictures/Upscale/Input -o ~/Pictures/Upscale/Output";
      ytm4a = "uv run yt-dlp -f 'ba[ext=m4a]' -o '%(title)s.%(ext)s' --cookies-from-browser firefox --no-check-certificates";

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

      #----- Network Tools Shortcuts -----
      tailup = "sudo tailscale up";
      taildown = "sudo tailscale down";

      #----- XDG Portal Tools -----
      "checkportals" = ''
        echo "🔍 XDG Portal Status Check"
        echo "══════════════════════════"

        # Check service status for each portal.
        echo "📊 Service Status:"
        for service in xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk; do
          echo "→ $service:"
          systemctl --user status $service | grep -E "Active:|●|○|↳" | sed 's/^/  /'
        done

        # Show recent portal logs.
        echo "\n📋 Recent Portal Logs:"
        journalctl -b | grep -iE "(xdg.*portal|portal.*xdg)" | tail -n 10 | while IFS= read -r line; do
          echo "  $line"
        done

        # Display DBus interface status for portals.
        echo "\n🔌 DBus Interface Status:"
        busctl --user list | grep portal | while IFS= read -r line; do
          echo "  $line"
        done

        # Check the portal process status.
        echo "\n🔍 Portal Process Check:"
        ps aux | grep -E "[x]dg-desktop-portal" | while IFS= read -r line; do
          echo "  $line"
        done
      '';

      #----- Home Manager Repo Aliases -----
      # Adjust the path below to the root of your hm repository.
      "hmpush" = "git -C ~/nixos push origin main --force";
      "hmpull" = "git -C ~/nixos fetch origin && git -C ~/nixos reset --hard origin/main";

      #----- Hardware Management Shortcut -----
      gpupower = "sudo nvidia-smi -pl";
    };
  };
}
