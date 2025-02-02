#─────────────────────────── 🌍 SYSTEM OPTIONS 🌍 ───────────────────────────#
# Defines the structure of system configuration options                      #
#──────────────────────────────────────────────────────────────────────────#
{lib, ...}: {
  # Basic user and system settings
  username = lib.mkOption {
    type = lib.types.str;
    description = "The username for the system.";
  };
  homeDirectory = lib.mkOption {
    type = lib.types.str;
    description = "The path to the user's home directory.";
  };
  hostname = lib.mkOption {
    type = lib.types.str;
    description = "The system hostname.";
  };
  stateVersion = lib.mkOption {
    type = lib.types.str;
    description = "The system state version.";
  };
  timezone = lib.mkOption {
    type = lib.types.str;
    description = "The system timezone.";
  };

  # Feature flags (defaulting to false)
  enableHyprland = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable the Hyprland desktop environment configuration.";
  };
  enableAgs = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable the Ags configuration.";
  };
  enableWayland = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable Wayland support.";
  };
  enableNvidia = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable Nvidia-specific configuration.";
  };
  enableGaming = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable gaming-specific configuration.";
  };
  enableDevelopment = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable development-related configuration.";
  };
  enableMedia = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable media-related configuration.";
  };
  enableCreative = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable creative-specific configuration.";
  };
  enableVirtualization = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable virtualization support.";
  };
  enableBackup = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable backup solutions.";
  };
  enableNeovim = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable Neovim integration.";
  };
  enableAndroid = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable Android-related settings.";
  };

  # Common paths
  flakeDir = lib.mkOption {
    type = lib.types.str;
    description = "The directory where the flake lives.";
  };
  musicDir = lib.mkOption {
    type = lib.types.str;
    description = "Directory for music files.";
  };
  dcimDir = lib.mkOption {
    type = lib.types.str;
    description = "Directory for pictures (DCIM).";
  };
  steamDir = lib.mkOption {
    type = lib.types.str;
    description = "Directory for Steam.";
  };
  wallpaperDir = lib.mkOption {
    type = lib.types.str;
    description = "Wallpaper directory.";
  };
  wallpaperVideoDir = lib.mkOption {
    type = lib.types.str;
    description = "Wallpaper video directory.";
  };

  # Default applications
  defaultBrowser = lib.mkOption {
    type = lib.types.str;
    description = "Default web browser.";
  };
  defaultEditor = lib.mkOption {
    type = lib.types.str;
    description = "Default text editor.";
  };
  defaultIde = lib.mkOption {
    type = lib.types.str;
    description = "Default IDE.";
  };
  defaultTerminal = lib.mkOption {
    type = lib.types.str;
    description = "Default terminal emulator.";
  };
  defaultFileManager = lib.mkOption {
    type = lib.types.str;
    description = "Default file manager.";
  };
  defaultLauncher = lib.mkOption {
    type = lib.types.str;
    description = "Default application launcher.";
  };
  defaultDiscord = lib.mkOption {
    type = lib.types.str;
    description = "Default Discord client.";
  };
  defaultArchiveManager = lib.mkOption {
    type = lib.types.str;
    description = "Default archive manager.";
  };
  defaultImageViewer = lib.mkOption {
    type = lib.types.str;
    description = "Default image viewer.";
  };
  defaultMediaPlayer = lib.mkOption {
    type = lib.types.str;
    description = "Default media player.";
  };

  # Git configuration
  gitName = lib.mkOption {
    type = lib.types.str;
    description = "Git username.";
  };
  gitEmail = lib.mkOption {
    type = lib.types.str;
    description = "Git email address.";
  };
  homeManagerRepoUrl = lib.mkOption {
    type = lib.types.str;
    description = "URL of the Home Manager repository.";
  };
}
