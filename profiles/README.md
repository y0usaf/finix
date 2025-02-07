
# NixOS Desktop Profile Example

This document outlines a complete system configuration for a NixOS desktop setup. It can serve as a starting point for your own custom profile, whether you're integrating it into NixOS or Home Manager.

## Getting Started

1. **Copy and Customize**  
   Duplicate this file (e.g., as `profiles/my-desktop.nix` or similar) and modify it according to your needs.

2. **Integrate**  
   Incorporate your customized version into your NixOS or Home Manager flake.

3. **Rebuild and Switch**  
   Rebuild your system configuration and switch over to the new profile.

For more details, refer to the [NixOS official documentation](https://nixos.org/manual/) or the [Home Manager documentation](https://nix-community.github.io/home-manager/).

---

## Configuration Details

Below is the complete configuration example:

```
{ pkgs, lib, ... }:
{
  # -- Basic User Information --
  username      = "exampleUser";         # Your system username, e.g., "alice"
  homeDirectory = "/home/exampleUser";   # Absolute path to the user's home directory

  # -- System Identification and Behavior --
  hostname     = "example-desktop";       # The network hostname for your system
  stateVersion = "24.11";                 # DO NOT CHANGE unless upgrading states
  timezone     = "America/New_York";      # Set your local timezone

  # -- Enabled Features --
  features = [
    "hyprland"    # Enables the Hyprland window manager configuration.
    "wayland"     # Required for using the Wayland display server.
    "nvidia"      # Installs Nvidia drivers (if applicable).
    "development" # Includes development tools and languages.
    "media"       # Multimedia support: players, codecs, etc.
    "backup"      # Tools for backups and data recovery.
  ];

  # -- Directory Settings --
  flakeDir          = "/home/exampleUser/nixos";          # Directory where your flake resides
  musicDir          = "$HOME/Music";                      # For music files
  dcimDir           = "$HOME/DCIM";                       # For images and photos
  steamDir          = "$HOME/.local/share/Steam";         # Directory for Steam data
  wallpaperDir      = "$HOME/DCIM/Wallpapers/32_9";         # For wallpaper images
  wallpaperVideoDir = "$HOME/DCIM/Wallpapers_Video";        # For video wallpapers

  # -- Default Applications --
  defaultBrowser = {
    package = pkgs.firefox;  # Browser package from Nixpkgs.
    command = "firefox";     # Command used to launch the browser.
  };

  defaultEditor = {
    package = pkgs.neovim;   # Neovim is used as the default editor.
    command = "nvim";        # Command for launching Neovim.
  };

  defaultTerminal = {
    package = pkgs.foot;     # Terminal emulator.
    command = "foot";        # Launch command for the terminal.
  };

  defaultFileManager = {
    package = pkgs.pcmanfm;  # File manager package.
    command = "pcmanfm";     # Command used to start the file manager.
  };

  defaultMediaPlayer = {
    package = pkgs.mpv;      # Media player package.
    command = "mpv";         # Command used to launch the media player.
  };

  # -- Git Configuration --
  gitName               = "Example User";                 # Your name for Git commits.
  gitEmail              = "example@domain.com";             # Your email address for Git.
  gitHomeManagerRepoUrl = "git@github.com:example/nixos.git"; # URL to your Home Manager repository.

  # -- Display & Font Settings --
  dpi          = 109;        # Display DPI for UI scaling.
  baseFontSize = 12;         # Base font size (points) for UI elements.
  cursorSize   = 24;         # Size for the mouse pointer.
  fonts = {
    main = [
      [ pkgs.nerd-fonts.iosevka-term-slab "IosevkaTermSlab Nerd Font Mono" ]
    ];
    fallback = [
      [ pkgs.noto-fonts-emoji   "Noto Color Emoji" ]
      [ pkgs.noto-fonts-cjk-sans "Noto Sans CJK" ]
      [ pkgs.font-awesome       "Font Awesome" ]
    ];
  };

  # -- Managed Directories --
  directories = {
    flake = {
      path = "/home/exampleUser/nixos";  # Directory where flake configurations are stored.
    };
    music = {
      path = "$HOME/Music";              # Music directory path.
    };
    dcim = {
      path = "$HOME/DCIM";               # DCIM (camera/photos) directory path.
    };
    steam = {
      path   = "$HOME/.local/share/Steam"; # Steam directory path.
      create = false;                     # Do not auto-create this directory.
    };
  };

  # Additional options can be added here following the same structure.
}
```

---

## Final Notes

After customizing this configuration for your needs, incorporate it into your flake and rebuild your system configuration to see the changes in effect.

Happy NixOS-ing!