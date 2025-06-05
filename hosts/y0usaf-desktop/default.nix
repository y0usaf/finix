# UNIFIED HOST CONFIGURATION for y0usaf-desktop
{pkgs, ...}: let
  username = "y0usaf";
  homeDir = "/home/${username}";
in {
  # Firewall configuration
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [25565]; # Minecraft server
  };
  cfg = {
    # SHARED CONFIGURATION - used by all module systems
    shared = {
      inherit username;
      homeDirectory = homeDir;
      hostname = "y0usaf-desktop";
      stateVersion = "24.11";
      timezone = "America/Toronto";
      config = "default";

      # User preferences shared across modules
      tokenDir = "${homeDir}/Tokens";

      # Zsh user preferences - now properly shared between system and home modules
      zsh = {
        cat-fetch = true;
        history-memory = 10000;
        history-storage = 10000;
        zellij = {
          enable = false;
        };
      };
    };

    system = {
      # Move imports inside system configuration to avoid HM exposure
      imports = [
        ./hardware-configuration.nix
        ./disko.nix
      ];

      hardware = {
        bluetooth = {
          enable = true;
        };
        nvidia = {
          enable = true;
          cuda.enable = true;
        };
        amdgpu.enable = false;
      };
    };

    # HJOME CONFIGURATION - simple interface like Home Manager
    hjome = {
      # Global Hjem settings
      clobberFiles = true;

      # Core configuration - DISABLED FOR BASIC TESTING
      # core = {
      #   environment.enable = true;
      # };

      # ui = {
      #   wayland.enable = true;
      #   ags.enable = true;
      #   hyprland = {
      #     enable = true;
      #     flake.enable = true;
      #     hy3.enable = true;
      #   };
      # };

      # Gaming modules - ALL gaming config in one place!
      gaming = {
        enable = true;
        controllers.enable = true;
        emulation = {
          wii-u.enable = true;
          gcn-wii.enable = true;
        };
        marvel-rivals = {
          engine.enable = true;
          gameusersettings.enable = true;
          marvelusersettings.enable = true;
        };
        balatro = {
          enable = true;
          enableLovelyInjector = true;
          enabledMods = ["steamodded" "talisman" "morespeeds" "cardsleeves" "multiplayer" "jokerdisplay" "pokermon" "aura" "handybalatro" "stickersalwaysshown"];
        };
        wukong = {
          enable = true;
        };
      };

      dev = {
        mcp.enable = true;
        cursor-ide.enable = true;
      };

      programs = {
        creative.enable = true;
        imv.enable = true;
        media.enable = true;
        qbittorrent.enable = true;
        obs.enable = true;
        pcmanfm.enable = true;
        obsidian.enable = true;
        vesktop.enable = true;
        # Migrated from Home Manager
        mpv.enable = true;
        bambu.enable = true;
        webapps.enable = true;
        zellij.enable = true;
      };
      tools = {
        spotdl.enable = true;
        yt-dlp.enable = true;
        nh = {
          enable = true;
          flake = "${homeDir}/nixos";
        };
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
        # Archive management tools
        "7z".enable = true;
        file-roller.enable = true;
      };

      shell = {
        zsh.enable = true;
      };
    };

    # HOME-MANAGER CONFIGURATION - COMMENTED OUT FOR HJEM TESTING
    /*
    home = {
      # Core module enables (former cfg.core - now organized under cfg.home)
      core = {
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
          enable = false;
          # User preferences now come from cfg.shared.zsh
        };
      };

      ui = {
        wayland.enable = true;
        ags.enable = false; # Disabled in Home Manager, now using Hjem
        cursor.enable = true;
        kitty.enable = false;
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
        discord.enable = true;

        android.enable = false;
        firefox.enable = true;

        music.enable = true;
        sway-launcher-desktop.enable = true;
        # streamlink and syncthing moved to user packages for simplicity

        bluetooth.enable = true;
      };

      # Gaming - now fully handled by Hjem

      # tools directory removed - all tools now handled by Hjem

      # Development
      dev = {
        docker.enable = true;
        fhs.enable = true;
        claude-code.enable = true;
        npm.enable = true;
        nvim.enable = true;
        python.enable = true;
        latex.enable = true;
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
          syncthing # File synchronization
          # Minecraft support
          prismlauncher
          temurin-bin-17 # Java 17 for most modern MC versions (PrismLauncher can manage others)
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
    */
  };
}
