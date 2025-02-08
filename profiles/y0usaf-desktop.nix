#───────────────────────── 🖥️ DESKTOP PROFILE 🖥️ ─────────────────────────#
# Personal configuration for y0usaf-desktop                                #
#──────────────────────────────────────────────────────────────────────────#
{pkgs, ...}: let
  username = "y0usaf";
  homeDir = "/home/${username}";
in {
  username = username;
  homeDirectory = homeDir;
  hostname = "y0usaf-desktop";
  stateVersion = "24.11";
  timezone = "America/Toronto";

  features = [
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
    "android"
    "webapps"
    "wallust"
    "syncthing"
    "vscode"
    "zellij"
    "music"
    "obs"
  ];

  flakeDir = "${homeDir}/nixos";
  musicDir = "${homeDir}/Music";
  dcimDir = "${homeDir}/DCIM";
  steamDir = "${homeDir}/.local/share/Steam";
  wallpaperDir = "${homeDir}/DCIM/Wallpapers/32_9";
  wallpaperVideoDir = "${homeDir}/DCIM/Wallpapers_Video";

  # Default applications using attribute set format
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

  gitName = "y0usaf";
  gitEmail = "OA99@Outlook.com";
  gitHomeManagerRepoUrl = "git@github.com:y0usaf/nixos.git";

  bookmarks = [
    "file://${homeDir}/Downloads Downloads"
    "file://${homeDir}/Music Music"
    "file://${homeDir}/DCIM DCIM"
    "file://${homeDir}/Pictures Pictures"
    "file://${homeDir}/nixos NixOS"
    "file://${homeDir}/Dev Dev"
  ];

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

  directories = {
    flake.path = "${homeDir}/nixos";
    music.path = "${homeDir}/Music";
    dcim.path = "${homeDir}/DCIM";
    steam = {
      path = "${homeDir}/.local/share/Steam";
      create = false; # Don't create Steam dir automatically
    };
  };

  personalPackages = with pkgs; [
    realesrgan-ncnn-vulkan
    streamlink-twitch-gui-bin
  ];
}
