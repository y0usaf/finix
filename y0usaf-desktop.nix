#───────────────────────── 🖥️ DESKTOP PROFILE 🖥️ ─────────────────────────#
# Personal configuration for y0usaf-desktop                                #
#──────────────────────────────────────────────────────────────────────────#
let
  username = "y0usaf";
in {
  # Basic settings
  username = username;
  homeDirectory = "/home/${username}";
  hostname = "y0usaf-desktop";
  stateVersion = "24.11";
  timezone = "America/Toronto";

  # Enable feature flags
  enableHyprland = true;
  enableAgs = true;
  enableWayland = true;
  enableNvidia = true;
  enableGaming = true;
  enableDevelopment = true;
  enableMedia = true;
  enableCreative = true;
  enableVirtualization = true;
  enableBackup = true;
  enableNeovim = true;
  enableAndroid = true;
  enableWebapps = true;

  # Common paths
  flakeDir = "/home/${username}/nixos";
  musicDir = "$HOME/Music";
  dcimDir = "$HOME/DCIM";
  steamDir = "$HOME/.local/share/Steam";
  wallpaperDir = "$HOME/DCIM/Wallpapers/32_9";
  wallpaperVideoDir = "$HOME/DCIM/Wallpapers_Video";

  # Default applications
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

  # Git configuration
  gitName = "y0usaf";
  gitEmail = "OA99@Outlook.com";
  homeManagerRepoUrl = "git@github.com:y0usaf/nixos.git";

  # Font configuration
  mainFont = {
    package = ["nerd-fonts" "iosevka-term-slab"];
    name = "IosevkaTermSlab NFM";
  };

  fallbackFonts = [
    {
      package = ["noto-fonts-emoji"];
      name = "Noto Color Emoji";
    }
    {
      package = ["noto-fonts"];
      name = "Noto Sans Symbols";
    }
    {
      package = ["noto-fonts"];
      name = "Noto Sans Symbols 2";
    }
    {
      package = ["dejavu_fonts"];
      name = "DejaVu Sans Mono";
    }
    {
      package = ["font-awesome"];
      name = "Font Awesome";
    }
    {
      package = ["noto-fonts-cjk-sans"];
      name = "Noto Sans CJK";
    }
    {
      package = ["noto-fonts"];
      name = "Noto Sans";
    }
  ];
}
