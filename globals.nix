#===============================================================================
#
#                     Global Variables Configuration
#
# Description:
#     Central configuration file defining global variables used throughout
#     the NixOS configuration. Contains:
#     - User settings
#     - System settings
#     - Common paths
#     - Default application choices
#
# Author: y0usaf
# Last Modified: 2025
#
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
