# UNIFIED HOST CONFIGURATION for y0usaf-laptop
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
    hostname = "y0usaf-laptop";
    stateVersion = "24.11";
    timezone = "America/Toronto";
    config = "default";
    tokenDir = "${homeDir}/Tokens";
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
    imports = [
      ../../system
      ./hardware-configuration.nix
      # ./disko.nix  # Disko disabled to match desktop
    ];
    hardware = {
      bluetooth = {
        enable = true;
      };
      nvidia.enable = false;
      amdgpu.enable = true;
    };
  };

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
      gtk = {
        enable = true;
        scale = 1.5;
      };
      hyprland = {
        enable = true;
        flake.enable = true;
        hy3.enable = true;
      };
      quickshell.enable = true;
      wallust.enable = false;
      wayland.enable = true;
      mako.enable = true;
    };
    programs = {
      bambu.enable = false;
      discord.enable = true;
      vesktop.enable = true;
      creative.enable = true;
      android.enable = true;
      firefox.enable = true;
      imv.enable = true;
      pcmanfm.enable = true;
      mpv.enable = true;
      obsidian.enable = true;
      media.enable = true;
      obs.enable = true;
      qbittorrent.enable = true;
      sway-launcher-desktop.enable = true;
      webapps.enable = true;
      bluetooth.enable = true;
    };
    dev = {
      docker.enable = true;
      claude-code.enable = true;
      mcp.enable = true;
      npm.enable = true;
      nvim.enable = true;
      python.enable = true;
      cursor-ide.enable = true;
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
          remoteBranch = "hjem";
        };
      };
      spotdl.enable = true;
      yt-dlp.enable = true;
      file-roller.enable = true;
      "7z".enable = true;
    };
    services = {
      polkitAgent.enable = true;
      formatNix.enable = true;
      nixosGitSync = {
        enable = true;
        remoteBranch = "hjem";
      };
      syncthing.enable = true;
    };
    gaming = {
      controllers.enable = true;
      emulation = {
        wii-u.enable = false;
        gcn-wii.enable = true;
      };
      balatro = {
        enable = true;
        enableLovelyInjector = true;
        enabledMods = ["steamodded" "talisman" "cryptid" "morespeeds" "cardsleeves" "multiplayer" "jokerdisplay"];
      };
    };
  };
}
