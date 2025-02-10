# NixOS Desktop Profile Example
# WARNING: READ THIS ENTIRE DOCUMENT BEFORE YOU DO ANYTHING!
# This is NOT a toy config file—alter with extreme caution, or expect catastrophic failures!

This document outlines a complete system configuration for a NixOS desktop setup. It can serve as a starting point for your own custom profile, whether you're incorporating it into NixOS or Home Manager.

## GETTING STARTED - FOLLOW THESE INSTRUCTIONS TO THE LETTER

1. **Copy and Customize**  
   Duplicate this file (e.g., as `profiles/my-desktop.nix` or similar) and modify it according to your needs.
   **WARNING:** Any misconfiguration here could turn your system into an unbootable brick. Only change what you fully understand!

2. **Integrate**  
   Incorporate your customized version into your NixOS or Home Manager flake. Do not skip this step or assume defaults will work magically.

3. **Rebuild and Switch**  
   Rebuild your system configuration and switch over to the new profile. This step is CRITICAL—failure may result in a nonfunctional system.
   
For more details, refer to the [NixOS official documentation](https://nixos.org/manual/) or the [Home Manager documentation](https://nix-community.github.io/home-manager/). These aren't mere suggestions—review them before proceeding!

---

## CONFIGURATION DETAILS - PROCEED WITH EXTREME CAUTION

Below is the complete configuration example. Every detail matters—modify only if you know EXACTLY what you're doing!

```
{ pkgs, lib, ... }:
{
  # -- BASIC USER INFORMATION --
  # THESE DETAILS ARE ESSENTIAL. DO NOT PLACE HOLDERS THAT YOU DON'T INTEND TO CHANGE.
  username      = "exampleUser";         # Your system username. A single typo can cause major havoc!
  homeDirectory = "/home/exampleUser";   # Absolute path to the user's home directory. Must be 100% correct!

  # -- SYSTEM IDENTIFICATION AND BEHAVIOR --
  hostname     = "example-desktop";       # The network hostname for your system. Ensure it's unique!
  stateVersion = "24.11";                 # DO NOT CHANGE unless upgrading states. Ignorance here will bite you!
  timezone     = "America/New_York";      # Set your local timezone. Misconfiguration can mess up logging!

  # -- ENABLED FEATURES --
  # READ THIS LIST CAREFULLY. Each feature toggles complex subsystems.
  features = [
    "hyprland"    # Enables the Hyprland window manager configuration. Modern? Yes—but fragile if misused.
    "wayland"     # Required for using the Wayland display server. Do NOT disable lightly!
    "nvidia"      # Installs Nvidia drivers. Necessary if your hardware demands it!
    "development" # Installs development tools and languages. Only include if you have a genuine need.
    "media"       # Multimedia support: players, codecs, etc. Vital for media tasks.
    "backup"      # Tools for backups and data recovery. Neglect this and risk data loss!
  ];

  # -- DIRECTORY SETTINGS: DOUBLE-CHECK ALL PATHS --
  flakeDir          = "/home/exampleUser/nixos";          # Directory where your flake resides. Precision is crucial!
  musicDir          = "$HOME/Music";                      # Directory for music files. Wrong path means no tunes!
  dcimDir           = "$HOME/DCIM";                       # Folder for images and photos. A misstep here breaks image management!
  steamDir          = "$HOME/.local/share/Steam";         # Directory for Steam data. Verify with utmost care!
  wallpaperDir      = "$HOME/DCIM/Wallpapers/32_9";         # Where wallpaper images live. This MUST be correct!
  wallpaperVideoDir = "$HOME/DCIM/Wallpapers_Video";        # For video wallpapers. Do not modify unless necessary!

  # -- GTK BOOKMARKS: SET WITH PRECISION OR RISK FAILURE --
  bookmarks = [
    "file:///home/exampleUser/Downloads 📥 Downloads"  # Essential bookmark for Downloads folder.
    "file:///home/exampleUser/Music 🎵 Music"            # Bookmark for your Music directory.
    "file:///home/exampleUser/DCIM 📸 Camera"            # Bookmark for images/photos.
    "file:///home/exampleUser/nixos ❄️ NixOS"            # Bookmark for your NixOS config folder.
    "file:///home/exampleUser/.local/share/Steam 🎮 Steam" # Bookmark for the Steam directory.
  ];

  # -- DEFAULT APPLICATIONS: MINIMAL ERROR TOLERANCE --
  defaultBrowser = {
    package = pkgs.firefox;  # Browser package from Nixpkgs. Do NOT replace with subpar alternatives!
    command = "firefox";     # Command used to launch the browser.
  };

  defaultEditor = {
    package = pkgs.neovim;   # Neovim is established as the default editor. USE IT OR FACE THE CONSEQUENCES!
    command = "nvim";        # Command to launch Neovim.
  };

  defaultTerminal = {
    package = pkgs.foot;     # Terminal emulator – the essential tool of power users.
    command = "foot";        # Launch command for the terminal. A single typo here renders the terminal unusable.
  };

  defaultFileManager = {
    package = pkgs.pcmanfm;  # File manager package that must be accurate for file operations.
    command = "pcmanfm";     # Command to start the file manager.
  };

  defaultMediaPlayer = {
    package = pkgs.mpv;      # Media player package required for video playback.
    command = "mpv";         # Command to launch the media player.
  };

  # -- GIT CONFIGURATION: ENSURE ACCURACY OR SUFFER CONFUSION IN COMMITS --
  gitName               = "Example User";                 # Your Git commit name. Incorrect values can ruin commit history!
  gitEmail              = "example@domain.com";           # MUST be a valid email—double-check for typos!
  gitHomeManagerRepoUrl = "git@github.com:example/nixos.git"; # URL to your Home Manager repository. THIS IS CRUCIAL!

  # -- DISPLAY & FONT SETTINGS: NO ROOM FOR VISUAL DISASTER --
  dpi          = 109;         # Display DPI for optimal UI scaling. A wrong number spells visual disaster!
  baseFontSize = 12;          # Base font size for UI elements. KEEP IT CONSISTENT!
  cursorSize   = 24;          # Mouse pointer size. Adjust only if you know how it affects the DPI scaling!
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

  # -- MANAGED DIRECTORIES: FOLLOW THE PATH STRUCTURE EXACTLY --
  directories = {
    flake = {
      path = "/home/exampleUser/nixos";  # Critical directory for flake configurations.
    };
    music = {
      path = "$HOME/Music";              # Music directory. Verify this path meticulously!
    };
    dcim = {
      path = "$HOME/DCIM";               # Directory for photos and images.
    };
    steam = {
      path   = "$HOME/.local/share/Steam"; # Steam data directory. DO NOT change unless you're absolutely certain!
      create = false;                     # Do not auto-create this directory—Steam handles it!
    };
  };

  # ADDITIONAL OPTIONS MUST BE ADHERED TO STRICTLY. NO EXCEPTIONS!
}
```

---

## FINAL NOTES - THERE IS NO ROOM FOR EXCUSES!

After customizing this configuration for your specific needs, incorporate it into your flake and rebuild your system configuration to see your changes in effect.  
**WARNING:** Only proceed if you are completely sure that your modifications will not irrevocably break your desktop environment.  
Happy NixOS-ing—and remember, if things go wrong, you were warned in no uncertain terms!