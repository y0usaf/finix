#─────────────────────────── 🌍 GLOBAL SETTINGS 🌍 ──────────────────────────#
# 👤 User Configuration | 🖥️ System Preferences | 📁 Common Paths           #
# 🚀 Default Applications | 💡 Core Settings First                          #
#──────────────────────────────────────────────────────────────────────────#
let
  username = "y0usaf";
in {
  #── 👤 User Settings ───────────────────#
  inherit username;
  homeDirectory = "/home/${username}";

  #── 🖥️ System Settings ────────────────#
  hostname = "y0usaf-desktop";
  stateVersion = "24.11";
  timezone = "America/Toronto";

  #── 🚦 Feature Flags ──────────────────#
  enableHyprland = true; # Enable/disable Hyprland
  enableAgs = true; # Enable/disable AGS
  enableWayland = true; # Enable/disable Wayland support
  enableNvidia = true;
  enableGaming = true; # Enable gaming-related packages and configurations
  enableDevelopment = true; # Enable development tools and environments
  enableMedia = true; # Enable media playback and editing tools
  enableCreative = true; # Enable creative tools (image editing, 3D, etc.)
  enableVirtualization = true; # Enable virtualization support
  enableBackup = true; # Enable backup services and configurations

  #── 📁 Common Paths ───────────────────#
  flakeDir = "/home/${username}/nixos";
  musicDir = "$HOME/Music";
  dcimDir = "$HOME/DCIM";
  steamDir = "$HOME/.local/share/Steam";
  wallpaperDir = "$HOME/DCIM/Wallpapers/32_9";
  wallpaperVideoDir = "$HOME/DCIM/Wallpapers_Video";

  #── 🚀 Default Applications ───────────#
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

  #── 🔧 Git Settings ──────────────────#
  gitName = "y0usaf";
  gitEmail = "OA99@Outlook.com";
  homeManagerRepoUrl = "git@github.com:y0usaf/nixos.git";
}
