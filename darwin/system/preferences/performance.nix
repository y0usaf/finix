_: {
  system.defaults.CustomUserPreferences = {
    # Global animation and performance tweaks
    "NSGlobalDomain" = {
      "NSScrollViewRubberbanding" = 0;
      "NSAutomaticWindowAnimationsEnabled" = 0;
      "NSScrollAnimationEnabled" = 0;
      "NSWindowResizeTime" = 0.001;
      "QLPanelAnimationDuration" = 0;
      "NSDocumentRevisionsWindowTransformAnimation" = 0;
      "NSToolbarFullScreenAnimationDuration" = 0;
      "NSBrowserColumnAnimationSpeedMultiplier" = 0;
      "NSAppSleepTime" = 0; # Disable app nap
    };

    # App-specific performance tweaks
    "com.apple.CoreData" = {
      "CrashOnDefects" = 0;
    };

    # Dock animation and performance settings
    "com.apple.dock" = {
      "autohide-time-modifier" = 0;
      "expose-animation-duration" = 0;
      "springboard-show-duration" = 0;
      "springboard-hide-duration" = 0;
      "springboard-page-duration" = 0;
      "launchAnim" = 0; # Disable app launch bounce animation
      "wvous-tl-corner" = 1; # Disable top-left hot corner
      "wvous-tr-corner" = 1; # Disable top-right hot corner
      "wvous-bl-corner" = 1; # Disable bottom-left hot corner
      "wvous-br-corner" = 1; # Disable bottom-right hot corner
    };
  };
}
