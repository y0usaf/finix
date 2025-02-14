{pkgs, ...}: let
  # Define the username
  username = "y0usaf";

  # Build the home directory path
  homeDir = "/home/${username}";
in {
  username = username;
  homeDirectory = homeDir;
  hostname = "y0usaf-laptop";
  stateVersion = "24.11";
  timezone = "America/Toronto";

  features = [
    "hyprland"
    "ags"
    "wayland"
    "gaming"
    "development"
    "media"
    "creative"
    "virtualization"
    "backup"
    "nvim"
    "android"
    "webapps"
    "wallust"
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
  ];

  # Directory Configurations
  flakeDir = "${homeDir}/nixos";
  musicDir = "${homeDir}/Music";
  dcimDir = "${homeDir}/DCIM";
  steamDir = "${homeDir}/.local/share/Steam";
  wallpaperDir = "${homeDir}/DCIM/Wallpapers/32_9";
  wallpaperVideoDir = "${homeDir}/DCIM/Wallpapers_Video";

  # Default Applications (same as desktop)
  defaultBrowser = {
    package = pkgs.firefox;
    command = "firefox";
  };
  defaultEditor = {
    package = pkgs.neovim;
    command = "nvim";
  };
  defaultIde = {
    package = pkgs.code-cursor;
    command = "cursor";
  };
  defaultTerminal = {
    package = pkgs.foot;
    command = "foot";
  };
  defaultFileManager = {
    package = pkgs.pcmanfm;
    command = "pcmanfm";
  };
  defaultLauncher = {
    package = pkgs.sway-launcher-desktop;
    command = "foot -a launcher sway-launcher-desktop";
  };
  defaultDiscord = {
    package = pkgs.discord;
    command = "discord";
  };
  defaultArchiveManager = {
    package = pkgs.p7zip;
    command = "7z";
  };
  defaultImageViewer = {
    package = pkgs.imv;
    command = "imv";
  };
  defaultMediaPlayer = {
    package = pkgs.mpv;
    command = "mpv";
  };

  # Git Configuration
  gitName = "y0usaf";
  gitEmail = "OA99@Outlook.com";
  gitHomeManagerRepoUrl = "git@github.com:y0usaf/nixos.git";

  # Bookmarks
  bookmarks = [
    "file://${homeDir}/Downloads Downloads"
    "file://${homeDir}/Music Music"
    "file://${homeDir}/DCIM DCIM"
    "file://${homeDir}/Pictures Pictures"
    "file://${homeDir}/nixos NixOS"
    "file://${homeDir}/Dev Dev"
    "file://${homeDir}/.local/share/Steam Steam"
  ];

  # Display settings (adjust these based on your laptop's screen)
  dpi = 96;
  baseFontSize = 12;
  cursorSize = 24;

  # Font Configuration
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

  # Directory Structure
  directories = {
    flake.path = "${homeDir}/nixos";
    music.path = "${homeDir}/Music";
    dcim.path = "${homeDir}/DCIM";
    steam = {
      path = "${homeDir}/.local/share/Steam";
      create = false;
    };
  };

  # Personal Packages
  personalPackages = with pkgs; [
    realesrgan-ncnn-vulkan
  ];
}
