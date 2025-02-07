#───────────────────────── 🖥️ DESKTOP PROFILE 🖥️ ─────────────────────────#
# Personal configuration for y0usaf-desktop                                #
#──────────────────────────────────────────────────────────────────────────#
{pkgs, ...}: let
  username = "y0usaf";
in {
  username = username;
  homeDirectory = "/home/${username}";
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
    "neovim"
    "android"
    "webapps"
    "wallust"
    "syncthing"
    "vscode"
  ];

  flakeDir = "/home/${username}/nixos";
  musicDir = "$HOME/Music";
  dcimDir = "$HOME/DCIM";
  steamDir = "$HOME/.local/share/Steam";
  wallpaperDir = "$HOME/DCIM/Wallpapers/32_9";
  wallpaperVideoDir = "$HOME/DCIM/Wallpapers_Video";

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
    "file:///home/${username}/Downloads Downloads"
    "file:///home/${username}/Music Music"
    "file:///home/${username}/DCIM DCIM"
    "file:///home/${username}/Pictures Pictures"
    "file:///home/${username}/nixos NixOS"
    "file:///home/${username}/Dev Dev"
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
    flake.path = "/home/${username}/nixos";
    music.path = "$HOME/Music";
    dcim.path = "$HOME/DCIM";
    steam = {
      path = "$HOME/.local/share/Steam";
      create = false; # Don't create Steam dir automatically
    };
  };

  personalPackages = with pkgs; [
    realesrgan-ncnn-vulkan
  ];
}
