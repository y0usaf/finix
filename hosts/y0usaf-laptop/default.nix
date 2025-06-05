# UNIFIED HOST CONFIGURATION for y0usaf-laptop
{pkgs, ...}: let
  username = "y0usaf";
  homeDir = "/home/${username}";
in {
  cfg = {
    # SYSTEM CONFIGURATION (includes hardware)
    system = {
      inherit username;
      homeDirectory = homeDir;
      hostname = "y0usaf-laptop";
      stateVersion = "24.11";
      timezone = "America/Toronto";
      config = "default";

      # Move imports inside system configuration to avoid HM exposure
      imports = [
        ./hardware-configuration.nix
        ./disko.nix
      ];

      hardware = {
        bluetooth = {
          enable = true;
        };
        nvidia.enable = false;
        amdgpu.enable = true;
      };
    };

    # HOME-MANAGER CONFIGURATION
    home = {
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

      # Appearance - adjusted for laptop display
      appearance = {
        dpi = 144;
        baseFontSize = 10;
        cursorSize = 24;
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
        bambu.enable = false; # Disabled for laptop
        discord.enable = true;

        creative.enable = true;
        chatgpt.enable = true;
        android.enable = true; # Enabled for laptop
        firefox.enable = true;
        imv.enable = true;
        mpv.enable = true;

        media.enable = true;
        music.enable = true;
        qbittorrent.enable = true;
        streamlink.enable = false; # Disabled for laptop
        sway-launcher-desktop.enable = true;
        syncthing.enable = true;
        webapps.enable = true;

        bluetooth.enable = true;
      };

      # Gaming
      gaming = {
        enable = true;
        controllers.enable = true;
        emulation = {
          wii-u.enable = false; # Disabled for laptop performance
          gcn-wii.enable = true;
        };
        balatro = {
          enable = true;
          enableLovelyInjector = true;
          enabledMods = ["steamodded" "talisman" "cryptid" "morespeeds" "overlay" "cardsleeves" "multiplayer" "jokerdisplay"];
        };
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
          ags
          astal.hyprland
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

    # SHARED CONFIGURATION (both system and home)
    core = {
      ssh.enable = true;
      xdg.enable = true;
      systemd = {
        enable = true;
        autoFormatNix = {
          enable = true;
          directory = "${homeDir}/nixos";
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
      env = {
        enable = true;
        tokenDir = "${homeDir}/Tokens";
      };
    };

    # HJOME CONFIGURATION
    hjome = {
      programs = {
        obs.enable = true;
        pcmanfm.enable = true;
        obsidian.enable = true;
        vesktop.enable = true;
      };
      tools = {
        spotdl.enable = true;
        yt-dlp.enable = true;
      };
    };
  };

  # AMD GPU specific configuration
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  users.users.${username}.extraGroups = ["docker"];
}
