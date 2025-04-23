# HOME-MANAGER CONFIGURATION for y0usaf-desktop
{pkgs, ...}: {
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
      discord.enable = true;
      creative.enable = true;
      chatgpt.enable = true;
      android.enable = false;
      firefox.enable = true;
      imv.enable = true;
      pcmanfm.enable = true;
      gaming = {
        enable = true;
        controllers.enable = true;
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
        "file://~/Downloads Downloads"
        "file://~/Music Music"
        "file://~/DCIM DCIM"
        "file://~/Pictures Pictures"
        "file://~/nixos NixOS"
        "file://~/Dev Dev"
        "file://~/.local/share/Steam Steam"
      ];
      packages = with pkgs; [
        realesrgan-ncnn-vulkan
        zoom-us
      ];
    };

    # Directories
    directories = {
      flake.path = "~/nixos";
      music.path = "~/Music";
      dcim.path = "~/DCIM";
      steam = {
        path = "~/.local/share/Steam";
        create = false;
      };
      wallpapers = {
        static.path = "~/DCIM/Wallpapers/32_9";
        video.path = "~/DCIM/Wallpapers_Video";
      };
    };
  };
}
