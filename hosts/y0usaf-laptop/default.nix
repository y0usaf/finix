# UNIFIED HOST CONFIGURATION for y0usaf-laptop
{pkgs, ...}: let
  username = "y0usaf";
  homeDir = "/home/${username}";
in {
  cfg = {
    # SHARED CONFIGURATION - used by all module systems
    shared = {
      inherit username;
      homeDirectory = homeDir;
      hostname = "y0usaf-laptop";
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
          enable = true;
        };
      };
    };

    # SYSTEM CONFIGURATION (includes hardware)
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
        nvidia.enable = false;
        amdgpu.enable = true;
      };
    };

    # HJOME CONFIGURATION - simple interface like Home Manager
    hjome = {
      # Global Hjem settings
      clobberFiles = true;

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

      # Core configuration
      core = {
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
            syncthing # File synchronization
            ags
            astal.hyprland
          ];
        };
      };

      ui = {
        hyprland = {
          enable = true;
          flake.enable = true;
          hy3.enable = true;
        };
        wayland.enable = true;
        ags.enable = true;
        foot.enable = true;
      };

      # Gaming modules - adjusted for laptop
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
          enabledMods = ["steamodded" "talisman" "cryptid" "morespeeds" "cardsleeves" "multiplayer" "jokerdisplay"];
        };
      };

      dev = {
        mcp.enable = true;
        cursor-ide.enable = true;
      };

      programs = {
        bambu.enable = false; # Disabled for laptop
        creative.enable = true;
        imv.enable = true;
        mpv.enable = true;
        media.enable = true;
        qbittorrent.enable = true;
        webapps.enable = true;
        obs.enable = true;
        pcmanfm.enable = true;
        obsidian.enable = true;
        vesktop.enable = true;
        zellij.enable = true;
        firefox.enable = true;
        discord.enable = true;
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
  };

  # AMD GPU specific configuration
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  users.users.${username}.extraGroups = ["docker"];
}
