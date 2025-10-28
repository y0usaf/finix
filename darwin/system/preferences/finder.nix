_: {
  system.defaults.CustomUserPreferences = {
    "com.apple.finder" = {
      "DisableAllAnimations" = true;
      "ShowExternalHardDrivesOnDesktop" = false;
      "ShowRemovableMediaOnDesktop" = false;
      "ShowMountedServersOnDesktop" = false;
      "AppleShowAllFiles" = true; # Show hidden files
      "FXEnableExtensionChangeWarning" = false; # Don't warn on extension change
      "_FXShowPosixPathInTitle" = true; # Show full path in title bar
      "FXDefaultSearchScope" = "SCcf"; # Search current folder by default
      "ShowStatusBar" = true; # Show status bar at bottom
      "ShowPathbar" = true; # Show path bar for breadcrumb navigation
    };

    # Prevent .DS_Store files on network volumes and external drives
    "com.apple.desktopservices" = {
      "DSDontWriteNetworkStores" = true;
      "DSDontWriteUSBStores" = true;
    };
  };
}
