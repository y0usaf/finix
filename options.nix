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
  # Each default application requires:
  # - package: The package name to be installed
  # - command: The command to execute the application
  defaultAppModule = types:
    lib.types.submodule {
      options = {
        package = lib.mkOption {
          type = lib.types.str;
          description = "Package name to install";
        };
        command = lib.mkOption {
          type = lib.types.str;
          description = "Command to execute the application";
        };
      };
    };

  defaultBrowser = lib.mkOption {
    type = defaultAppModule;
    description = "Default web browser configuration.";
  };
  defaultEditor = lib.mkOption {
    type = defaultAppModule;
    description = "Default text editor configuration.";
  };
  defaultIde = lib.mkOption {
    type = defaultAppModule;
    description = "Default IDE configuration.";
  };
  defaultTerminal = lib.mkOption {
    type = defaultAppModule;
    description = "Default terminal emulator configuration.";
  };
  defaultFileManager = lib.mkOption {
    type = defaultAppModule;
    description = "Default file manager configuration.";
  };
  defaultLauncher = lib.mkOption {
    type = defaultAppModule;
    description = "Default application launcher configuration.";
  };
  defaultDiscord = lib.mkOption {
    type = defaultAppModule;
    description = "Default Discord client configuration.";
  };
  defaultArchiveManager = lib.mkOption {
    type = defaultAppModule;
    description = "Default archive manager configuration.";
  };
  defaultImageViewer = lib.mkOption {
    type = defaultAppModule;
    description = "Default image viewer configuration.";
  };
  defaultMediaPlayer = lib.mkOption {
    type = defaultAppModule;
    description = "Default media player configuration.";
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
