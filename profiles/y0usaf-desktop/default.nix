#───────────────────────── Aggressive Comments: DESKTOP PROFILE ─────────────────────────#
# This file is the heart of your desktop configuration for 'y0usaf-desktop'.
# Every setting here has been painstakingly chosen—alter ANYTHING only if you know EXACTLY what you're doing!
# If you break something, don't say we didn't warn you. Read every single comment!
{pkgs, ...}: let
  # Define the username.
  # WARNING: Change this only if your actual Linux username DOES NOT match "y0usaf"!
  username = "y0usaf";

  # Build the home directory path from the username above.
  # MAKE SURE the resulting path is correct, or your system will cry for help.
  homeDir = "/home/${username}";
in {
  #=======================================================================
  # Module Configurations
  #=======================================================================
  # Enable specific modules based on your needs
  modules = {
    # System Identity and Core Settings
    system = {
      # Explicitly set the username in the configuration.
      username = username;

      # Set the path to your home directory.
      # This is a critical parameter; many paths in this file depend on it.
      homeDirectory = homeDir;

      # Set your machine's hostname.
      # NOTE: This should be unique across your network.
      hostname = "y0usaf-desktop";

      # Define the NixOS state version.
      # BEWARE: Changing this version may cause rebuild issues or incompatibility with existing configurations.
      stateVersion = "24.11";

      # Define your timezone.
      # CHANGE THIS if you're not in America/Toronto, or suffer the consequences.
      timezone = "America/Toronto";
    };

    # UI and Display Modules
    ui = {
      hyprland.enable = true;
      wayland.enable = true;
    };

    # Appearance settings
    appearance = {
      dpi = 109; # Set the DPI value. A wrong value here can ruin your display scaling.
      baseFontSize = 12; # The base font size across applications—adjust if everything looks too small or huge.
      cursorSize = 24; # The cursor size. Perfect for high-resolution displays; change ONLY if necessary.

      # Font Settings
      fonts = {
        main = [
          # Main font: IosevkaTermSlab Nerd Font Mono gives you a clean, modern look in terminals and editors.
          [pkgs.nerd-fonts.iosevka-term-slab "IosevkaTermSlab Nerd Font Mono"]
        ];
        fallback = [
          # Fallback for emojis. Without this, expect a lot of missing characters!
          [pkgs.noto-fonts-emoji "Noto Color Emoji"]
          # Fallback for CJK characters. Verify if you work with Asian scripts.
          [pkgs.noto-fonts-cjk-sans "Noto Sans CJK"]
          # Font Awesome for icons and symbols—essential to maintain UI consistency.
          [pkgs.font-awesome "Font Awesome"]
        ];
      };
    };

    # Core System Modules
    core = {
      nvidia.enable = true;
      nvidia.cuda.enable = true;
      amdgpu.enable = false;
      ssh.enable = true;
      xdg.enable = true;
      zsh.enable = true;
      systemd = {
        enable = true;
        autoFormatNix = {
          enable = true;
          directory = "${homeDir}/nixos";
        };
      };
    };

    # Directory and Path Configurations
    directories = {
      flake.path = "${homeDir}/nixos";
      music.path = "${homeDir}/Music";
      dcim.path = "${homeDir}/DCIM";
      steam = {
        path = "${homeDir}/.local/share/Steam";
        create = false; # DO NOT automatically create this directory—Steam manages it!
      };
      wallpapers = {
        static.path = "${homeDir}/DCIM/Wallpapers/32_9";
        video.path = "${homeDir}/DCIM/Wallpapers_Video";
      };
    };

    # User Preferences and Customization
    user = {
      # Git and Version Control Settings
      git = {
        name = "y0usaf"; # Your Git author name.
        email = "OA99@Outlook.com"; # Your Git email. Double-check it—it's used for commit history.
        homeManagerRepoUrl = "git@github.com:y0usaf/nixos.git"; # URL to your home manager repository.
      };

      # Bookmarks for file manager
      bookmarks = [
        "file://${homeDir}/Downloads Downloads" # Bookmark for the Downloads folder.
        "file://${homeDir}/Music Music" # Bookmark for your Music folder.
        "file://${homeDir}/DCIM DCIM" # Bookmark for your DCIM/photos folder.
        "file://${homeDir}/Pictures Pictures" # Bookmark for Pictures.
        "file://${homeDir}/nixos NixOS" # Bookmark for your NixOS config folder.
        "file://${homeDir}/Dev Dev" # Bookmark for your Development directory.
        "file://${homeDir}/.local/share/Steam Steam" # Bookmark for the Steam folder.
      ];
    };

    # Application Modules
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

    dev = {
      fhs.enable = true;
    };
  };

  #=======================================================================
  # Additional Packages
  #=======================================================================
  # Add any personal packages here. This package is for image upscaling.
  personalPackages = with pkgs; [
    realesrgan-ncnn-vulkan
  ];
}
