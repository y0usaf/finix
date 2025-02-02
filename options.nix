#─────────────────────────── 🌍 SYSTEM OPTIONS 🌍 ───────────────────────────#
{lib, ...}: let
  # Core packages that will always be installed
  corePackages = [
    "git"
    "curl"
    "wget"
    "cachix"
    "unzip"
    "bash"
    "vim"
    "dconf"
    "lsd"
    "alejandra"
    "lm_sensors"
  ];

  # Simplify the mkFeature helper by using more concise type definitions
  mkFeature = description:
    lib.types.submodule {
      options = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable ${description}";
        };
        packages = lib.mkOption {
          type = with lib.types; listOf str;
          default = []; # Empty default since we'll use corePackages separately
          description = "Packages to install when this feature is enabled";
        };
      };
    };

  # Simplify defaultAppModule similarly
  defaultAppModule = lib.types.submodule {
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
in {
  # Core packages configuration
  corePackages = lib.mkOption {
    type = with lib.types; listOf str;
    default = [
      "git"
      "curl"
      "wget"
      "cachix"
      "unzip"
      "bash"
      "vim"
      "dconf"
      "lsd"
      "alejandra"
      "lm_sensors"
    ];
    description = "Essential packages that will always be installed";
  };

  # Basic user and system settings
  system = lib.mkOption {
    type = lib.types.submodule {
      options = {
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
        packages = lib.mkOption {
          type = with lib.types; listOf str;
          default = corePackages;
          description = "Core system packages that will always be installed.";
        };
      };
    };
  };

  # Features with associated packages
  features = lib.mkOption {
    type = lib.types.submodule {
      options = {
        hyprland = lib.mkOption {
          type = mkFeature "Hyprland desktop environment";
        };
        ags = lib.mkOption {
          type = mkFeature "Ags configuration";
        };
        wayland = lib.mkOption {
          type = mkFeature "Wayland support";
        };
        nvidia = lib.mkOption {
          type = mkFeature "Nvidia-specific configuration";
        };
        gaming = lib.mkOption {
          type = mkFeature "gaming-specific configuration";
        };
        development = lib.mkOption {
          type = mkFeature "development-related configuration";
        };
        media = lib.mkOption {
          type = mkFeature "media-related configuration";
        };
        creative = lib.mkOption {
          type = mkFeature "creative-specific configuration";
        };
        virtualization = lib.mkOption {
          type = mkFeature "virtualization support";
        };
        backup = lib.mkOption {
          type = mkFeature "backup solutions";
        };
        neovim = lib.mkOption {
          type = mkFeature "Neovim integration";
        };
        android = lib.mkOption {
          type = mkFeature "Android-related settings";
        };
        webapps = lib.mkOption {
          type = mkFeature "Web applications and browser integration";
        };
      };
    };
  };

  # Paths configuration
  paths = lib.mkOption {
    type = lib.types.submodule {
      options = {
        flake = lib.mkOption {
          type = lib.types.str;
          description = "The directory where the flake lives.";
        };
        music = lib.mkOption {
          type = lib.types.str;
          description = "Directory for music files.";
        };
        dcim = lib.mkOption {
          type = lib.types.str;
          description = "Directory for pictures (DCIM).";
        };
        steam = lib.mkOption {
          type = lib.types.str;
          description = "Directory for Steam.";
        };
        wallpaper = lib.mkOption {
          type = lib.types.str;
          description = "Wallpaper directory.";
        };
        wallpaperVideo = lib.mkOption {
          type = lib.types.str;
          description = "Wallpaper video directory.";
        };
      };
    };
  };

  # Default applications configuration
  defaultApps = lib.mkOption {
    type = lib.types.submodule {
      options = {
        browser = lib.mkOption {
          type = defaultAppModule;
          description = "Default web browser configuration.";
        };
        editor = lib.mkOption {
          type = defaultAppModule;
          description = "Default text editor configuration.";
        };
        ide = lib.mkOption {
          type = defaultAppModule;
          description = "Default IDE configuration.";
        };
        terminal = lib.mkOption {
          type = defaultAppModule;
          description = "Default terminal emulator configuration.";
        };
        fileManager = lib.mkOption {
          type = defaultAppModule;
          description = "Default file manager configuration.";
        };
        launcher = lib.mkOption {
          type = defaultAppModule;
          description = "Default application launcher configuration.";
        };
        discord = lib.mkOption {
          type = defaultAppModule;
          description = "Default Discord client configuration.";
        };
        archiveManager = lib.mkOption {
          type = defaultAppModule;
          description = "Default archive manager configuration.";
        };
        imageViewer = lib.mkOption {
          type = defaultAppModule;
          description = "Default image viewer configuration.";
        };
        mediaPlayer = lib.mkOption {
          type = defaultAppModule;
          description = "Default media player configuration.";
        };
      };
    };
  };

  # Git configuration
  git = lib.mkOption {
    type = lib.types.submodule {
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          description = "Git username.";
        };
        email = lib.mkOption {
          type = lib.types.str;
          description = "Git email address.";
        };
        homeManagerRepoUrl = lib.mkOption {
          type = lib.types.str;
          description = "URL of the Home Manager repository.";
        };
      };
    };
  };
}
