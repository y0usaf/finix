# Example NixOS Desktop Profile
# =============================================================================
# This file defines a complete system configuration for a NixOS desktop.
# Each section is annotated with detailed comments that explain the purpose
# of the individual configuration options.
#
# To use this profile:
#   1. Copy and customize this file (e.g., as profiles/my-desktop.nix).
#   2. Integrate it into your NixOS or Home Manager flake.
#   3. Rebuild and switch your system configuration.
#
# For more details, refer to the NixOS and Home Manager official docs.

{ pkgs, lib, ... }:

{
  # -- Basic User Information --
  # Set the username and home directory for your system.
  username = "exampleUser";                # Your system username, e.g., "alice"
  homeDirectory = "/home/exampleUser";       # Absolute path to the user's home directory

  # -- System Identification and Behavior --
  hostname = "example-desktop";              # The network hostname for your system
  stateVersion = "24.11";                    # DO NOT CHANGE unless upgrading states
  timezone = "America/New_York";             # Set your local timezone

  # -- Enabled Features --
  # Each feature can toggle sets of packages and additional configuration.
  features = [
    "hyprland"         # Enables the Hyprland window manager configuration.
    "wayland"          # Required for using Wayland display server.
    "nvidia"           # Installs Nvidia drivers (if applicable).
    "development"      # Includes development tools and languages.
    "media"            # Multimedia support: players, codecs, etc.
    "backup"           # Tools for backups and data recovery.
    # You can add more features as long as they are defined in options.nix.
  ];

  # -- Directory Settings --
  # Define paths for important directories and resources.
  flakeDir = "/home/exampleUser/nixos";        # Directory where your flake resides
  musicDir = "$HOME/Music";                    # For music files
  dcimDir = "$HOME/DCIM";                      # For images and photos
  steamDir = "$HOME/.local/share/Steam";       # Directory for Steam data
  wallpaperDir = "$HOME/DCIM/Wallpapers/32_9";   # For wallpaper images
  wallpaperVideoDir = "$HOME/DCIM/Wallpapers_Video"; # For video wallpapers

  # -- Default Applications --
  # Configure which packages and commands should be used as the system's defaults.
  defaultBrowser = {
    package = pkgs.firefox;                   # Browser package from Nixpkgs.
    command = "firefox";                      # Command used to launch the browser.
  };
  defaultEditor = {
    package = pkgs.neovim;                    # Neovim is used as the default editor.
    command = "nvim";                         # Command for launching Neovim.
  };
  defaultTerminal = {
    package = pkgs.foot;                      # Terminal emulator.
    command = "foot";                         # Launch command for the terminal.
  };
  defaultFileManager = {
    package = pkgs.pcmanfm;                   # File manager package.
    command = "pcmanfm";                      # Command used to start the file manager.
  };
  defaultMediaPlayer = {
    package = pkgs.mpv;                       # Media player package.
    command = "mpv";                          # Command used to launch the media player.
  };

  # -- Git Configuration --
  # Provide your Git identity for version control tasks.
  gitName = "Example User";                  # Your name for Git commits.
  gitEmail = "example@domain.com";           # Your email address for Git.
  gitHomeManagerRepoUrl = "git@github.com:example/nixos.git"; # URL to your Home Manager repository.

  # -- Display & Font Settings --
  # Customize display scaling and fonts.
  dpi = 109;                                 # Display DPI for UI scaling.
  baseFontSize = 12;                         # Base font size (points) for UI elements.
  cursorSize = 24;                           # Size for the mouse pointer.
  fonts = {
    main = [
      [pkgs.nerd-fonts.iosevka-term-slab "IosevkaTermSlab Nerd Font Mono"]
      # ^-- Primary monospace font for terminals and code editors.
    ];
    fallback = [
      [pkgs.noto-fonts-emoji "Noto Color Emoji"]   # Emoji support.
      [pkgs.noto-fonts-cjk-sans "Noto Sans CJK"]     # Support for CJK characters.
      [pkgs.font-awesome "Font Awesome"]             # Icon font.
    ];
  };

  # -- Managed Directories --
  # Define directories to be automatically managed by your system.
  directories = {
    flake = {
      path = "/home/exampleUser/nixos";         # Directory where flake configurations are stored.
    };
    music = {
      path = "$HOME/Music";                      # Music directory path.
    };
    dcim = {
      path = "$HOME/DCIM";                       # DCIM (camera/photos) directory path.
    };
    steam = {
      path = "$HOME/.local/share/Steam";         # Steam directory path.
      create = false;                            # Set to false if you do not want this directory auto-created.
    };
  };

  # Additional options can be added here following the same structure.
} 