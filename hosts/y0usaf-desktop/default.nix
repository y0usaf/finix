# UNIFIED HOST CONFIGURATION for y0usaf-desktop
{pkgs, ...}: let
  username = "y0usaf";
  homeDir = "/home/${username}";
in {
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
        enableFancyPrompt = true;
        zellij = {
          enable = true;
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
      # Default Applications - Migrated to home

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
        # environment.enable = true;
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
      };

      ui = {
        wayland.enable = true;
        # foot.enable = true; # Migrated to home
        ags.enable = true;
        # hyprland migrated to home
      };

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

      # dev = {
      #   mcp.enable = true;
      #   cursor-ide.enable = true;
      #   claude-code.enable = true;
      #   docker.enable = true;
      #   npm.enable = true;
      #   latex.enable = true;
      #   nvim.enable = true;
      # };

      # programs = {
      #   # All programs migrated to home
      # };
      # tools = {
      #   # All tools migrated to home
      # };

      # shell = {
      #   # zsh.enable = true; # Migrated to home
      # };
    };

    # HOME CONFIGURATION - Maid-based modules
    home = {
      core = {
        packages.enable = true;
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
      };
      ui = {
        foot.enable = true;
        hyprland = {
          enable = true;
          flake.enable = true;
          hy3.enable = false;
        };
      };
      programs = {
        vesktop.enable = true;
        webapps.enable = true;
        firefox.enable = true;
        discord.enable = true;
        zellij.enable = true;
        obsidian.enable = true;
        creative.enable = true;
        media.enable = true;
        # zen-browser.enable = true; # Removed due to hash issues
        bluetooth.enable = true;
        obs.enable = true;
        bambu.enable = true;
        imv.enable = true;
        mpv.enable = true;
        pcmanfm.enable = true;
        qbittorrent.enable = true;
        sway-launcher-desktop.enable = true;
      };
      shell = {
        zsh.enable = true;
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
        nh = {
          enable = true;
          flake = "${homeDir}/nixos";
        };
        "7z".enable = true;
        file-roller.enable = true;
        spotdl.enable = true;
        yt-dlp.enable = true;
      };
      services = {
        polkitAgent.enable = true;
        formatNix.enable = true;
        nixosGitSync = {
          enable = true;
          remoteBranch = "hjem";
        };
      };
    };
  };
}
