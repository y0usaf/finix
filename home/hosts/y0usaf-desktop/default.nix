# HOME-MANAGER CONFIGURATION for y0usaf-desktop
{pkgs, ...}: let
  username = "y0usaf";
  homeDir = "/home/${username}";
in {
  cfg = {
    # UI and Display
    ui = {
      hyprland = {
        enable = true;
        flake.enable = true;
        hy3.enable = true;
      };
      wayland.enable = true;
      ags.enable = false;
      cursor.enable = true;
      foot.enable = true;
      gtk.enable = true;
      wallust.enable = false;
      mako.enable = true;
    };

    # Appearance
    appearance = {
      dpi = 109;
      baseFontSize = 12;
      cursorSize = 24;
      fonts = {
        main = [
          [pkgs.nerd-fonts.iosevka-term-slab "IosevkaTermSlab Nerd Font Mono"]
        ];
        fallback = [
          [pkgs.noto-fonts-emoji "Noto Color Emoji"]
          [pkgs.noto-fonts-cjk-sans "Noto Sans CJK"]
          [pkgs.font-awesome "Font Awesome"]
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
      blueman.enable = true; 
      discord.enable = true;
      creative.enable = true;
      chatgpt.enable = true;
      android.enable = false;
      firefox.enable = true;
      imv.enable = true;
      pcmanfm.enable = true;
      gaming = {
        enable = true;
        emulation = {
          wii-u.enable = true;
          gcn-wii.enable = true;
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
        homeManagerRepoUrl = "git@github.com:y0usaf/nixos.git";
      };
      spotdl.enable = true;
      yt-dlp.enable = true;
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

    # Core User Preferences
    core = {
      # Hardware-related settings are now pulled from system configuration
      # SSH settings are pulled from system configuration
      
      # Local home-specific settings
      xdg = {
        enable = true;
      };
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
    };

    # Additional settings may go here

    # User Preferences
    user = {
      bookmarks = [
        "file://${homeDir}/Downloads Downloads"
        "file://${homeDir}/Music Music"
        "file://${homeDir}/DCIM DCIM"
        "file://${homeDir}/Pictures Pictures"
        "file://${homeDir}/nixos NixOS"
        "file://${homeDir}/Dev Dev"
        "file://${homeDir}/.local/share/Steam Steam"
      ];
      packages = with pkgs; [
        realesrgan-ncnn-vulkan
        zoom-us
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
