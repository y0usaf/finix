#═══════════════════════════ 🔧 CORE SYSTEM MODULE 🔧 ═══════════════════════════#
{
  config, # HM config object
  lib, # Nixpkgs library functions
  pkgs, # Nixpkgs package set
  inputs, # Flake inputs (needed if profile comes from flake)
  profile, # User profile data (assuming passed down)
  ...
}: let
  # Type definitions for options
  t = lib.types;
  mkOpt = type: description: lib.mkOption {inherit type description;};
  # Define shorthand for boolean type
  mkBool = t.bool;
  # Define a shorthand for string type
  mkStr = t.str;

  # mkOptDef builds an option with a type, default value, and a description.
  mkOptDef = type: default: description: lib.mkOption {inherit type default description;};

  ######################################################################
  #                           Submodule Types                          #
  ######################################################################

  # Define common structure for default application configuration
  defaultAppModule = t.submodule {
    options = {
      # package: Specifies the Nix package derivation to install for the application.
      # Can be null if you only want to specify a command without installing a package.
      package = mkOptDef (t.nullOr t.package) null "Package derivation to install (optional)";
      # command: Specifies the command to run the application.
      # If null, the default behavior is to use the package name.
      command = mkOptDef mkStr null "Command to execute the application. Defaults to package name if null";
    };
  };

  # Define common structure for directory configuration
  dirModule = t.submodule {
    options = {
      # path: Defines the absolute path to the directory.
      path = mkOpt mkStr "Absolute path to the directory";
      # create: Determines if the directory should be created automatically if not found.
      create = mkOptDef mkBool true "Whether to create the directory if it doesn't exist";
    };
  };

  # --- Package Definitions (Moved from home.nix) ---
  # Extract default applications from profile
  defaultApps = [
    profile.modules.defaults.terminal
    profile.modules.defaults.browser
    profile.modules.defaults.fileManager
    profile.modules.defaults.launcher
    profile.modules.defaults.ide
    profile.modules.defaults.mediaPlayer
    profile.modules.defaults.imageViewer
    profile.modules.defaults.discord
    profile.modules.defaults.archiveManager
  ];

  # Extract package attribute from each app and filter out nulls
  userPackages = lib.filter (p: p != null) (map (app: app.package) defaultApps);

  # Combine all package sources (Base + Profile Defaults + User Defined)
  basePackages = with pkgs; [
    # Essential CLI tools
    git
    curl
    wget
    cachix
    unzip
    bash
    vim # Or replace with profile.modules.defaults.editor.package if defined
    lsd
    alejandra
    tree
    bottom
    psmisc

    # System interaction
    dconf # Already here, needed for dconf.enable
    lm_sensors
    networkmanager # Might be needed for applets/widgets
  ];

  # Final list includes base, profile-derived defaults, and explicit user packages
  finalPackages = basePackages ++ userPackages ++ (profile.modules.user.packages or []);
in {
  # --- Options Definition (Existing) ---
  options.modules = {
    # System identity and core settings (used by config section below)
    system = {
      username = mkOpt mkStr "The username for the system.";
      hostname = mkOpt mkStr "The system hostname.";
      homeDirectory = mkOpt mkStr "The path to the user's home directory.";
      stateVersion = mkOpt mkStr "The system state version.";
      timezone = mkOpt mkStr "The system timezone.";
      config = mkOpt mkStr "The system configuration type.";
    };

    # Core system modules (e.g., GPU)
    core = {
      nvidia = {
        enable = lib.mkEnableOption "NVIDIA GPU support";
      };
      amdgpu = {
        enable = lib.mkEnableOption "AMD GPU support";
      };
      # --- Environment Settings Options (from env.nix) ---
      env = {
        enable = lib.mkEnableOption "home environment configuration (session vars/path)";
        tokenDir = lib.mkOption {
          type = t.str;
          default = "$HOME/Tokens";
          description = "Directory containing token files to be loaded by zsh as env variables";
        };
      };
    };

    # User-defined packages (used in package calculation above)
    user = {
      packages = lib.mkOption {
        type = t.listOf t.package;
        default = [];
        description = "List of additional user-specific packages.";
      };

      # --- User Specific Settings (bookmarks, git) ---
      bookmarks = mkOptDef (t.listOf mkStr) [] "GTK bookmarks";
      git = mkOpt (t.submodule {
        options = {
          name = mkOpt mkStr "Git user name";
          email = mkOpt mkStr "Git user email";
          homeManagerRepoUrl = mkOpt mkStr "URL to home manager repository";
        };
      }) "Git configuration";
    };

    # Default applications (used in package calculation above)
    # Structure defined by defaultAppModule
    defaults = {
      browser = mkOpt defaultAppModule "Default web browser configuration.";
      editor = mkOpt defaultAppModule "Default text editor configuration.";
      ide = mkOpt defaultAppModule "Default IDE configuration.";
      terminal = mkOpt defaultAppModule "Default terminal emulator configuration.";
      fileManager = mkOpt defaultAppModule "Default file manager configuration.";
      launcher = mkOpt defaultAppModule "Default application launcher configuration.";
      discord = mkOpt defaultAppModule "Default Discord client configuration.";
      archiveManager = mkOpt defaultAppModule "Default archive manager configuration.";
      imageViewer = mkOpt defaultAppModule "Default image viewer configuration.";
      mediaPlayer = mkOpt defaultAppModule "Default media player configuration.";
    };

    # Directory configurations (Structure defined by dirModule)
    directories = {
      flake = mkOpt dirModule "The directory where the flake lives.";
      music = mkOpt dirModule "Directory for music files.";
      dcim = mkOpt dirModule "Directory for pictures (DCIM).";
      steam = mkOpt dirModule "Directory for Steam.";
      wallpapers = mkOpt (t.submodule {
        options = {
          static = mkOpt dirModule "Wallpaper directory for static images.";
          video = mkOpt dirModule "Wallpaper directory for videos.";
        };
      }) "Wallpaper directories configuration";
    };
  };

  # --- Configuration Application (Merged) ---
  config = {
    # Core Home Settings (Moved from home.nix)
    home = {
      # Use values defined in options.modules.system, accessed via config.modules
      username = config.modules.system.username;
      homeDirectory = config.modules.system.homeDirectory;
      stateVersion = config.modules.system.stateVersion;
      enableNixpkgsReleaseCheck = false; # Keep setting from original home.nix

      # Set packages using the combined list
      packages = finalPackages;

      # --- General Environment Settings (from env.nix) ---
      # Conditionally apply session variables and path from core.env settings
      sessionVariables = lib.mkIf config.modules.core.env.enable {
        LIBSEAT_BACKEND = "logind";
        # Add other user session variables here
      };
      sessionPath = lib.mkIf config.modules.core.env.enable [
        "$HOME/.local/bin"
        "/usr/lib/google-cloud-sdk/bin"
      ];
    };

    # Enable dconf (Moved from home.nix)
    dconf.enable = true;

    # Pass down module config for other modules (Needed for options access)
    # This assumes profile is passed to the top-level home.nix and then down
    # If home.nix doesn't pass profile.modules down as config.modules, this needs adjustment
    modules = profile.modules or {};

    # --- DELETED BLOCK ---
    # The duplicate home = lib.mkIf block that caused the error was here
  };
}
