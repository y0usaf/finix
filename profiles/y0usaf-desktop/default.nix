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

  #=======================================================================
  # Feature Flags
  #=======================================================================
  # The following list enables specific features and modules.
  # DO NOT fiddle with these unless you completely understand what each flag triggers.
  features = [
    "core"
    "ssh"
    "systemd"
    "appearance"

    "zsh"
    "git"
    "xdg"
    "fonts"
    "foot"
    "gtk"
    "cursor"
    "firefox"
    "hyprland"
    "wayland"
    "ags"
    "nvidia"
    "gaming"
    "development"
    "media"
    "creative"
    "virtualization"
    "backup"
    "nvim"
    "webapps"
    #"wallust"
    "syncthing"
    "vscode"
    "zellij"
    "music"
    "obs"
    "streamlink"
    "chatgpt"
    "python"
    "sync-tokens"
    "qbittorrent"
    "npm"
    "discord"
    "cursor-ide"
    "npins"
    "sway-launcher-desktop"
    "claude-code"
    "claude-desktop"
    "mcp"
  ];

  #=======================================================================
  # Directory Configurations
  #=======================================================================
  # Define important directories used in the configuration.
  flakeDir = "${homeDir}/nixos"; # The directory where your Nix flake configuration lives.
  musicDir = "${homeDir}/Music"; # Path to your Music folder.
  dcimDir = "${homeDir}/DCIM"; # Where your DCIM/photos are stored.
  steamDir = "${homeDir}/.local/share/Steam"; # Path for Steam; ensure this is correct!
  # Wallpapers are split into static (32:9) and video types.
  wallpaperDir = "${homeDir}/DCIM/Wallpapers/32_9"; # Directory for 32:9 wallpapers.
  wallpaperVideoDir = "${homeDir}/DCIM/Wallpapers_Video"; # Directory for video wallpapers.

  #=======================================================================
  # Default Applications
  #=======================================================================
  # Each default application is defined with its corresponding package and command.
  # MODIFY these ONLY if you're sure about the dependencies and behavior changes.
  defaultBrowser = {
    package = null; # The go-to browser is Firefox.
    command = "firefox"; # Command line trigger for Firefox.
  };
  defaultEditor = {
    package = pkgs.neovim; # Neovim is your editor. Trust it.
    command = "nvim"; # Launch Neovim with the 'nvim' command.
  };
  defaultIde = {
    package = null; # IDE for coding with a modern twist.
    command = "cursor"; # The command that fires up the IDE.
  };
  defaultTerminal = {
    package = pkgs.foot; # Foot terminal: sleek, minimal, and Wayland-friendly.
    command = "foot"; # Command for launching the terminal.
  };
  defaultFileManager = {
    package = pkgs.pcmanfm; # Use PCManFM for file management.
    command = "pcmanfm"; # Command to run PCManFM.
  };
  defaultLauncher = {
    package = null; # Sway launcher customized for your workflow.
    command = "foot -a 'launcher' ~/.config/scripts/sway-launcher-desktop.sh";
  };
  defaultDiscord = {
    # Reference the command only, not the package
    package = null; # Remove package definition to avoid collision
    command = "discord-canary"; # Command to launch Discord Canary
  };
  defaultArchiveManager = {
    package = pkgs.p7zip; # Use p7zip for all your archive needs.
    command = "7z"; # Command to invoke p7zip.
  };
  defaultImageViewer = {
    package = pkgs.imv; # The image viewer of choice.
    command = "imv"; # Run it using this command.
  };
  defaultMediaPlayer = {
    package = pkgs.mpv; # MPV for playing your videos.
    command = "mpv"; # Command to start MPV.
  };

  #=======================================================================
  # Git and Version Control Settings
  #=======================================================================
  # Set up your credentials for Git. These MUST match your actual identity.
  gitName = "y0usaf"; # Your Git author name.
  gitEmail = "OA99@Outlook.com"; # Your Git email. Double-check it—it's used for commit history.
  gitHomeManagerRepoUrl = "git@github.com:y0usaf/nixos.git"; # URL to your home manager repository.

  #=======================================================================
  # Bookmarks
  #=======================================================================
  # Predefine your bookmarks for quick access in your file manager.
  bookmarks = [
    "file://${homeDir}/Downloads Downloads" # Bookmark for the Downloads folder.
    "file://${homeDir}/Music Music" # Bookmark for your Music folder.
    "file://${homeDir}/DCIM DCIM" # Bookmark for your DCIM/photos folder.
    "file://${homeDir}/Pictures Pictures" # Bookmark for Pictures.
    "file://${homeDir}/nixos NixOS" # Bookmark for your NixOS config folder.
    "file://${homeDir}/Dev Dev" # Bookmark for your Development directory.
    "file://${homeDir}/.local/share/Steam Steam" # Bookmark for the Steam folder.
  ];

  #=======================================================================
  # Appearance and UI Scaling
  #=======================================================================
  dpi = 109; # Set the DPI value. A wrong value here can ruin your display scaling.
  baseFontSize = 12; # The base font size across applications—adjust if everything looks too small or huge.
  cursorSize = 24; # The cursor size. Perfect for high-resolution displays; change ONLY if necessary.

  #=======================================================================
  # Font Settings
  #=======================================================================
  # Specify the primary and fallback fonts to prevent any missing-character disasters.
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

  #=======================================================================
  # Directory Structure Configuration
  #=======================================================================
  directories = {
    # Path to the Nix flake configuration directory.
    flake.path = "${homeDir}/nixos";
    # Music directory path.
    music.path = "${homeDir}/Music";
    # DCIM directory path for photos.
    dcim.path = "${homeDir}/DCIM";
    # Configuration for the Steam directory.
    steam = {
      path = "${homeDir}/.local/share/Steam";
      create = false; # DO NOT automatically create this directory—Steam manages it!
    };
  };

  #=======================================================================
  # Personal Packages
  #=======================================================================
  # Add any personal packages here. This package is for image upscaling.
  personalPackages = with pkgs; [
    realesrgan-ncnn-vulkan
  ];
}
