# DESKTOP PROFILE
{pkgs, ...}: let
  username = "y0usaf";
  homeDir = "/home/${username}";
in {
  # Core System Configuration
  modules = {
    system = {
      username = username;
      homeDirectory = homeDir;
      hostname = "y0usaf-desktop";
      stateVersion = "24.11";
      timezone = "America/Toronto";
    };

    # Core Modules
    core = {
      git = {
        enable = true;
        name = "y0usaf";
        email = "OA99@Outlook.com";
        homeManagerRepoUrl = "git@github.com:y0usaf/nixos.git";
      };
      nvidia = {
        enable = true;
        cuda.enable = true;
      };
      amdgpu.enable = false;
      ssh.enable = true;
      xdg.enable = true;
      zsh = {
        enable = true;
        cat-fetch = true;
        history-memory = 10000;
        history-storage = 10000;
        zellij.enable = true;
      };
      systemd = {
        enable = true;
        autoFormatNix = {
          enable = true;
          directory = "${homeDir}/nixos";
        };
      };
    };

    # UI and Display
    ui = {
      hyprland.enable = true;
      wayland.enable = true;
      ags.enable = true;
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
      browser = {
        package = null;
        command = "firefox";
      };
      editor = {
        package = pkgs.neovim;
        command = "nvim";
      };
      ide = {
        package = null;
        command = "cursor";
      };
      terminal = {
        package = pkgs.foot;
        command = "foot";
      };
      fileManager = {
        package = pkgs.pcmanfm;
        command = "pcmanfm";
      };
      launcher = {
        package = null;
        command = "foot -a 'launcher' ~/.config/scripts/sway-launcher-desktop.sh";
      };
      discord = {
        package = null;
        command = "discord-canary";
      };
      archiveManager = {
        package = pkgs.p7zip;
        command = "7z";
      };
      imageViewer = {
        package = pkgs.imv;
        command = "imv";
      };
      mediaPlayer = {
        package = pkgs.mpv;
        command = "mpv";
      };
    };

    # Applications
    apps = {
      discord.enable = true;
      creative.enable = true;
      chatgpt.enable = true;
      android.enable = false;
      firefox.enable = true;
      gaming.enable = true;
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

    # Development
    dev = {
      fhs.enable = true;
      claude-code.enable = true;
      mcp.enable = true;
      npm.enable = true;
      nvim.enable = true;
      python.enable = true;
      cursor-ide.enable = true;
      voice-input = {
        enable = true;
        model = "tiny"; # Options: tiny, base, small, medium, large
        recordTime = 10; # Maximum recording time in seconds
      };
    };

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
