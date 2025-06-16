# UNIFIED HOST CONFIGURATION for y0usaf-desktop
{
  pkgs,
  inputs,
  ...
}: let
  username = "y0usaf";
  homeDir = "/home/${username}";
in {
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
      ../../system
      ./hardware-configuration.nix
      # ./disko.nix  # Temporarily disabled - partitions not created yet
    ];
    
    # Hardware configuration - host-level options
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
      appearance = {
        enable = true;
        dpi = 109;
        baseFontSize = 12;
        cursorSize = 36;
        fonts = {
          main = [
            {
              package = inputs.fast-fonts.packages.x86_64-linux.default;
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
      user.enable = true;
    };
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
    ui = {
      ags.enable = true;
      cursor.enable = true;
      fonts.enable = true;
      foot.enable = true;
      gtk.enable = true;
      hyprland = {
        enable = true;
        flake.enable = true;
        hy3.enable = false;
      };
      wallust.enable = true;
      wayland.enable = true;
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
      # android.enable = true; # TODO: Debug import issue
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
          remoteBranch = "main";
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
        remoteBranch = "main";
      };
    };
    gaming = {
      core.enable = true;
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
  };
}
