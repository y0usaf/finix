# HOME-MANAGER CONFIGURATION for y0usaf-desktop
{pkgs, ...}: let
  username = "y0usaf";
  homeDir = "/home/${username}";
in {
  cfg = {
    ui = {
      hyprland = {
        enable = true;
        flake.enable = true;
        hy3.enable = true;
      };
      wayland.enable = true;
      ags.enable = true;
      cursor.enable = true;
      foot.enable = true;
      gtk = {
        enable = true;
        scale = 1.5;
      };
      wallust.enable = false;
      mako.enable = true;
    };

    # Appearance
    appearance = {
      dpi = 109;
      baseFontSize = 12;
      cursorSize = 36;
      fonts = {
        main = [
          {
            package = pkgs.fastFonts;
            name = "Fast_Mono";
          }
        ];
        fallback = [
          {
            package = pkgs.noto-fonts-emoji;
            name = "Noto Color Emoji";
          }
          {
            package = pkgs.noto-fonts-cjk-sans;
            name = "Noto Sans CJK";
          }
          {
            package = pkgs.font-awesome;
            name = "Font Awesome";
          }
        ];
      };
    };

    # Default Applications
    defaults = {
      browser = "firefox";
      editor = "nvim";
      ide = "cursor";
      terminal = "foot";
      fileManager = "pcmanfm";
      launcher = "foot -a 'launcher' ~/.config/scripts/sway-launcher-desktop.sh";
      discord = "discord-canary";
      archiveManager = "7z";
      imageViewer = "imv";
      mediaPlayer = "mpv";
    };

    # Applications
    programs = {
      bambu.enable = true;
      discord.enable = true;
      vesktop.enable = true;
      creative.enable = true;
      chatgpt.enable = true;
      android.enable = false;
      firefox.enable = true;
      imv.enable = true;
      pcmanfm.enable = true;
      mpv.enable = true;
      obsidian.enable = true;
      gaming = {
        enable = true;
        controllers.enable = true;
        emulation = {
          wii-u.enable = true;
          gcn-wii.enable = true;
        };
        balatro = {
          enable = true;
          enableLovelyInjector = true;
          enabledMods = ["steamodded" "talisman" "cryptid" "morespeeds" "overlay" "cardsleeves" "multiplayer"];
        };
      };
      media.enable = true;
      music.enable = true;
      obs.enable = true;
      qbittorrent.enable = true;
      streamlink.enable = false;
      sway-launcher-desktop.enable = true;
      syncthing.enable = true;
      webapps.enable = true;
      zen-browser.enable = false;
    };

    tools = {
      git = {
        enable = true;
        name = "y0usaf";
        email = "OA99@Outlook.com";
        nixos-git-sync = {
          enable = true;
          nixosRepoUrl = "git@github.com:y0usaf/nixos.git";
          remoteBranch = "hjem";
        };
      };
      spotdl.enable = true;
      yt-dlp.enable = true;
      file-roller.enable = true;
      "7z".enable = true;
    };

    # Development
    dev = {
      docker.enable = true;
      fhs.enable = true;
      claude-code.enable = true;
      mcp.enable = true;
      npm.enable = true;
      nvim.enable = true;
      python.enable = true;
      cursor-ide.enable = true;
      latex.enable = true;
    };

    # Core User Preferences
    core = {
      # Local home-specific settings
      xdg = {
        enable = true;
      };
      systemd = {
        enable = true;
        autoFormatNix = {
          enable = true;
          directory = "~/nixos";
        };
      };
      zsh = {
        enable = true;
        cat-fetch = true;
        history-memory = 10000;
        history-storage = 10000;
        zellij = {
          enable = true;
        };
      };
    };

    # Programs related to Bluetooth
    programs.bluetooth = {
      enable = true;
    };

    # User Preferences
    user = {
      bookmarks = [
        "file:///home/${username}/Downloads Downloads"
        "file:///home/${username}/Music Music"
        "file:///home/${username}/DCIM DCIM"
        "file:///home/${username}/Pictures Pictures"
        "file:///home/${username}/nixos NixOS"
        "file:///home/${username}/Dev Dev"
        "file:///home/${username}/.local/share/Steam Steam"
      ];
      packages = with pkgs; [
        realesrgan-ncnn-vulkan
        fontforge
      ];
    };

    # Directories
    directories = {
      flake.path = "${homeDir}/nixos";
      music.path = "${homeDir}/Music";
      dcim.path = "${homeDir}/DCIM";
      steam = {
        path = "${homeDir}/.local/share/Steam";
        create = false;
      };
      wallpapers = {
        static.path = "${homeDir}/DCIM/Wallpapers/32_9";
        video.path = "${homeDir}/DCIM/Wallpapers_Video";
      };
    };
  };
}
