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
  mkStr = t.str;
  mkBool = t.bool;

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
  # Now defaultApps is a list of packages (or nulls), so we just filter nulls.
  userPackages = lib.filter (p: p != null) defaultApps;

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
    };

    # User-defined packages (used in package calculation above)
    user = {
      packages = lib.mkOption {
        type = t.listOf t.package;
        default = [];
        description = "List of additional user-specific packages.";
      };
    };

    # Default applications (used in package calculation above)
    # These should now just be packages (or null if not set)
    defaults = {
      terminal = lib.mkOption {
        type = t.nullOr t.package;
        default = null;
        description = "Default terminal emulator package.";
      };
      browser = lib.mkOption {
        type = t.nullOr t.package;
        default = null;
        description = "Default web browser package.";
      };
      fileManager = lib.mkOption {
        type = t.nullOr t.package;
        default = null;
        description = "Default file manager package.";
      };
      launcher = lib.mkOption {
        type = t.nullOr t.package;
        default = null;
        description = "Default application launcher package.";
      };
      ide = lib.mkOption {
        type = t.nullOr t.package;
        default = null;
        description = "Default IDE/text editor package.";
      };
      mediaPlayer = lib.mkOption {
        type = t.nullOr t.package;
        default = null;
        description = "Default media player package.";
      };
      imageViewer = lib.mkOption {
        type = t.nullOr t.package;
        default = null;
        description = "Default image viewer package.";
      };
      discord = lib.mkOption {
        type = t.nullOr t.package;
        default = null;
        description = "Discord package (if used).";
      };
      archiveManager = lib.mkOption {
        type = t.nullOr t.package;
        default = null;
        description = "Default archive manager package.";
      };
      # editor = lib.mkOption { type = t.nullOr t.package; default = null; }; # Consider adding
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
    };

    # Enable dconf (Moved from home.nix)
    dconf.enable = true;

    # Pass down module config for other modules (Needed for options access)
    # This assumes profile is passed to the top-level home.nix and then down
    # If home.nix doesn't pass profile.modules down as config.modules, this needs adjustment
    modules = profile.modules or {};
  };
}
