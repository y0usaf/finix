# HOST CONFIGURATION for y0usaf-desktop
# Separated system and home configurations - no shared dependencies
{
  pkgs,
  inputs,
  ...
}: let
  username = "y0usaf";
  homeDir = "/home/${username}";
  hostname = "y0usaf-desktop";
  stateVersion = "24.11";
  timezone = "America/Toronto";
in {
  # SYSTEM CONFIGURATION - self-contained, no home dependencies
  system = {
    # Module imports for system-level configuration
    imports = [
      ../../system
      ./hardware-configuration.nix
      # ./disko.nix  # Temporarily disabled - partitions not created yet
    ];

    # Core system identity and settings
    username = username;
    hostname = hostname;
    homeDirectory = homeDir;
    stateVersion = stateVersion;
    timezone = timezone;
    profile = "default";

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
      display.outputs = {
        "DP-4" = {
          mode = "5120x1440@239.76";
        };
        "DP-3" = {
          mode = "5120x1440@239.76";
        };
        "DP-2" = {
          mode = "5120x1440@239.76";
        };
        "DP-1" = {
          mode = "5120x1440@239.76";
        };
        "eDP-1" = {
          mode = "1920x1080@300.00";
        };
      };
    };

    # System-wide service declarations - what this host supports
    services = {
      docker.enable = true; # Container development
      waydroid.enable = false; # Android emulation (disabled - doesn't work with Nvidia)
      controllers.enable = true; # Gaming controller support
    };
  };

  # HOME CONFIGURATION - Keep existing structure for now
  # TODO: Update home modules to use systemValues instead of shared
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
      quickshell.enable = true;
      wallust.enable = true;
      wayland.enable = true;
    };
    programs = {
      vesktop.enable = true;
      webapps.enable = true;
      firefox.enable = true;
      discord.enable = true;
      obsidian.enable = true;
      creative.enable = true;
      media.enable = true;
      bluetooth.enable = true;
      obs.enable = true;
      bambu.enable = true;
      imv.enable = true;
      mpv.enable = true;
      pcmanfm.enable = true;
      qbittorrent.enable = true;
      sway-launcher-desktop.enable = true;
    };
    dev = {
      cursor-ide.enable = true;
      claude-code.enable = true;
      mcp.enable = true;
      docker.enable = true;
      nvim = {
        enable = true;
        neovide = false;
      };
      repomix.enable = true;
    };
    shell = {
      zsh.enable = true;
      cat-fetch.enable = true;
      zellij.enable = true;
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
      jj = {
        enable = true;
        name = "y0usaf";
        email = "OA99@Outlook.com";
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
      syncthing.enable = true;
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
