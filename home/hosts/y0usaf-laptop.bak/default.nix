# HOME-MANAGER CONFIGURATION for y0usaf-laptop
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
      ags.enable = true;
      cursor.enable = true;
      foot.enable = true;
      gtk = {
        enable = true;
        scale = 1;
      };
      wallust.enable = true;
      mako.enable = true;
    };

    # Appearance
    appearance = {
      dpi = 144;
      baseFontSize = 10;
      cursorSize = 16;
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
      browser = {
        package = pkgs.firefox;
        command = "firefox";
      };
      editor = {
        package = pkgs.neovim;
        command = "nvim";
      };
      ide = {
        package = pkgs.code-cursor;
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
        package = pkgs.sway-launcher-desktop;
        command = "foot -a launcher sway-launcher-desktop";
      };
      discord = {
        package = pkgs.discord;
        command = "discord";
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
    programs = {
      discord.enable = true;
      creative.enable = true;
      chatgpt.enable = true;
      android.enable = true;
      firefox.enable = true;
      gaming.enable = true;
      media.enable = true;
      music.enable = true;
      obs.enable = true;
      qbittorrent.enable = true;
      streamlink.enable = true;
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
        nixos-git-sync = {
          enable = true;
          nixosRepoUrl = "git@github.com:y0usaf/nixos.git";
          remoteBranch = "hjem";
        };
      };
      spotdl.enable = true;
      yt-dlp.enable = true;
    };

    # Development
    dev = {
      docker.enable = true;
      fhs.enable = true;
      claude-code.enable = true;
      npm.enable = true;
      nvim.enable = true;
      python.enable = true;
      cursor-ide.enable = true;
      voice-input.enable = false;
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
