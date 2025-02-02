#─────────────────────────── 🌍 SYSTEM OPTIONS 🌍 ───────────────────────────#
{lib, ...}: let
  # Common type shorthands for clarity
  mkStr = lib.types.str;
  mkBool = lib.types.bool;
  mkListOfStr = lib.types.listOf lib.types.str;

  # Default packages for various options
  defaultCorePackages = [
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

  # Helper to create a feature submodule with 'enable' and 'packages' options
  mkFeature = description:
    lib.types.submodule {
      options = {
        enable = lib.mkOption {
          type = mkBool;
          default = false;
          description = "Enable " + description;
        };
        packages = lib.mkOption {
          type = mkListOfStr;
          default = [];
          description = "Packages to install when this feature is enabled";
        };
      };
    };

  # Submodule for default application configurations
  defaultAppModule = lib.types.submodule {
    options = {
      package = lib.mkOption {
        type = mkStr;
        description = "Package name to install";
      };
      command = lib.mkOption {
        type = mkStr;
        description = "Command to execute the application";
      };
    };
  };
in {
  # Core packages configuration
  corePackages = lib.mkOption {
    type = mkListOfStr;
    default = defaultCorePackages;
    description = "Essential packages that will always be installed";
  };

  # Basic user and system settings
  system = lib.mkOption {
    type = lib.types.submodule {
      options = {
        username = lib.mkOption {
          type = mkStr;
          description = "The username for the system.";
        };
        homeDirectory = lib.mkOption {
          type = mkStr;
          description = "The path to the user's home directory.";
        };
        hostname = lib.mkOption {
          type = mkStr;
          description = "The system hostname.";
        };
        stateVersion = lib.mkOption {
          type = mkStr;
          description = "The system state version.";
        };
        timezone = lib.mkOption {
          type = mkStr;
          description = "The system timezone.";
        };
        packages = lib.mkOption {
          type = mkListOfStr;
          default = defaultCorePackages;
          description = "Core system packages that will always be installed.";
        };
      };
    };
  };

  # Features with associated packages
  features = lib.mkOption {
    type = lib.types.submodule {
      options = {
        hyprland = lib.mkOption {type = mkFeature "Hyprland desktop environment";};
        ags = lib.mkOption {type = mkFeature "Ags configuration";};
        wayland = lib.mkOption {type = mkFeature "Wayland support";};
        nvidia = lib.mkOption {type = mkFeature "Nvidia-specific configuration";};
        gaming = lib.mkOption {type = mkFeature "gaming-specific configuration";};
        development = lib.mkOption {type = mkFeature "development-related configuration";};
        media = lib.mkOption {type = mkFeature "media-related configuration";};
        creative = lib.mkOption {type = mkFeature "creative-specific configuration";};
        virtualization = lib.mkOption {type = mkFeature "virtualization support";};
        backup = lib.mkOption {type = mkFeature "backup solutions";};
        neovim = lib.mkOption {type = mkFeature "Neovim integration";};
        android = lib.mkOption {type = mkFeature "Android-related settings";};
        webapps = lib.mkOption {type = mkFeature "Web applications and browser integration";};
      };
    };
  };

  # Paths configuration
  paths = lib.mkOption {
    type = lib.types.submodule {
      options = {
        flake = lib.mkOption {
          type = mkStr;
          description = "The directory where the flake lives.";
        };
        music = lib.mkOption {
          type = mkStr;
          description = "Directory for music files.";
        };
        dcim = lib.mkOption {
          type = mkStr;
          description = "Directory for pictures (DCIM).";
        };
        steam = lib.mkOption {
          type = mkStr;
          description = "Directory for Steam.";
        };
        wallpaper = lib.mkOption {
          type = mkStr;
          description = "Wallpaper directory.";
        };
        wallpaperVideo = lib.mkOption {
          type = mkStr;
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
          type = mkStr;
          description = "Git username.";
        };
        email = lib.mkOption {
          type = mkStr;
          description = "Git email address.";
        };
        homeManagerRepoUrl = lib.mkOption {
          type = mkStr;
          description = "URL of the Home Manager repository.";
        };
      };
    };
  };
}
