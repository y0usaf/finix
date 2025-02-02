#───────────────────────── 🖥️ DESKTOP PROFILE 🖥️ ─────────────────────────#
# Personal configuration for y0usaf-desktop                                #
#──────────────────────────────────────────────────────────────────────────#
let
  username = "y0usaf";
in {
  # Basic user and system settings
  inherit username;
  homeDirectory = "/home/${username}";
  hostname = "y0usaf-desktop";
  stateVersion = "24.11";
  timezone = "America/Toronto";

  # Feature flags
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

  # Common paths
  flakeDir = "/home/${username}/nixos";
  musicDir = "$HOME/Music";
  dcimDir = "$HOME/DCIM";
  steamDir = "$HOME/.local/share/Steam";
  wallpaperDir = "$HOME/DCIM/Wallpapers/32_9";
  wallpaperVideoDir = "$HOME/DCIM/Wallpapers_Video";

  # Default applications
  defaultBrowser = "firefox";
  defaultEditor = "nvim";
  defaultIde = "cursor";
  defaultTerminal = "foot";
  defaultFileManager = "pcmanfm";
  defaultLauncher = "foot -a launcher sway-launcher-desktop";
  defaultDiscord = "vesktop";
  defaultArchiveManager = "p7zip";
  defaultImageViewer = "imv";
  defaultMediaPlayer = "mpv";

  # Git configuration
  gitName = "y0usaf";
  gitEmail = "OA99@Outlook.com";
  homeManagerRepoUrl = "git@github.com:y0usaf/nixos.git";
}
