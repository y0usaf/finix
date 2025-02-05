#───────────────────────── 🖥️ DESKTOP PROFILE 🖥️ ─────────────────────────#
# Personal configuration for y0usaf-desktop                                #
#──────────────────────────────────────────────────────────────────────────#
let
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
  ];

  flakeDir = "/home/${username}/nixos";
  musicDir = "$HOME/Music";
  dcimDir = "$HOME/DCIM";
  steamDir = "$HOME/.local/share/Steam";
  wallpaperDir = "$HOME/DCIM/Wallpapers/32_9";
  wallpaperVideoDir = "$HOME/DCIM/Wallpapers_Video";

  defaultBrowser = {
    package = "firefox";
    command = "firefox";
  };
  defaultEditor = {
    package = "neovim";
    command = "nvim";
  };
  defaultIde = {
    package = "code-cursor";
    command = "cursor";
  };
  defaultTerminal = {
    package = "foot";
    command = "foot";
  };
  defaultFileManager = {
    package = "pcmanfm";
    command = "pcmanfm";
  };
  defaultLauncher = {
    package = "sway-launcher-desktop";
    command = "foot -a launcher sway-launcher-desktop";
  };
  defaultDiscord = {
    package = "vesktop";
    command = "vesktop";
  };
  defaultArchiveManager = {
    package = "p7zip";
    command = "7z";
  };
  defaultImageViewer = {
    package = "imv";
    command = "imv";
  };
  defaultMediaPlayer = {
    package = "mpv";
    command = "mpv";
  };

  gitName = "y0usaf";
  gitEmail = "OA99@Outlook.com";
  gitHomeManagerRepoUrl = "git@github.com:y0usaf/nixos.git";

  dpi = 109;
  baseFontSize = 12;
  cursorSize = 24;

  mainFont = {
    package = [["terminus_font_ttf"]];
    name = "Terminus (TTF)";
  };

  fallbackFonts = [
    {
      package = [["noto-fonts-emoji"]];
      name = "Noto Color Emoji";
    }
    {
      package = [["noto-fonts-cjk-sans"]];
      name = "Noto Sans CJK";
    }
    {
      package = [["font-awesome"]];
      name = "Font Awesome";
    }
  ];
}
