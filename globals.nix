#===============================================================================
#                          🌍 Global Settings 🌍
#===============================================================================
# 👤 User Configuration
# 🖥️ System Preferences
# 📁 Common Paths
# 🚀 Default Applications
#
# 💡 Edit this file first when changing core settings
#===============================================================================
let
  username = "y0usaf";
in {
  # User Settings
  inherit username;
  homeDirectory = "/home/${username}";

  # System Settings
  hostname = "y0usaf-desktop";
  stateVersion = "24.11";
  timezone = "America/Toronto";

  # Feature Flags
  enableHyprland = true; # Enable/disable Hyprland
  enableAgs = true; # Enable/disable AGS
  enableWayland = true; # Enable/disable Wayland support

  # Hardware Settings
  gpuType = "nvidia";

  # Common Paths
  musicDir = "$HOME/Music";
  dcimDir = "$HOME/DCIM";
  steamDir = "$HOME/.local/share/Steam";
  wallpaperDir = "$HOME/DCIM/Wallpapers/32_9";
  wallpaperVideoDir = "$HOME/DCIM/Wallpapers_Video";

  # Default Applications
  defaultBrowser = "firefox";
  defaultEditor = "nvim";
  defaultIde = "cursor";
  defaultTerminal = "foot";
  defaultFileManager = "pcmanfm";
  defaultLauncher = "foot -a launcher sway-launcher-desktop";
  defaultDiscord = "vesktop";

  # Git Settings
  gitName = "y0usaf";
  gitEmail = "OA99@Outlook.com";
  homeManagerRepoUrl = "git@github.com:y0usaf/nixos.git";
}
