{...}: {
  # Disable macOS bloatware and unnecessary services

  # Set primary user for user-specific defaults
  system.primaryUser = "y0usaf";

  # Disable various system services
  system.defaults.LaunchServices.LSQuarantine = false; # Disable "Are you sure you want to open this application?" dialog

  # Dock settings - hide unwanted apps
  system.defaults.dock = {
    show-recents = false;
    static-only = true; # Only show open applications
    # Remove all default apps from dock (user can add back what they want)
  };

  # Disable unwanted features
  system.defaults.CustomUserPreferences = {
    # Disable FaceTime auto-launch
    "com.apple.FaceTime" = {
      "AutoAcceptInvites" = false;
    };

    # Disable iCloud prompts
    "com.apple.SetupAssistant" = {
      "DidSeeCloudSetup" = true;
      "DidSeeSyncSetup" = true;
      "DidSeeSyncSetup2" = true;
    };

    # Disable Apple Music and TV prompts
    "com.apple.Music" = {
      "userWantsPlaybackNotifications" = false;
    };

    # Disable Siri
    "com.apple.assistant.support" = {
      "Assistant Enabled" = false;
    };
  };

  # Disable Siri system-wide
  system.defaults.CustomSystemPreferences = {
    "com.apple.assistant.support" = {
      "Assistant Enabled" = 0;
    };
  };

  # Note: You cannot fully remove system apps like FaceTime, Music, TV, etc.
  # due to System Integrity Protection (SIP). However, you can:
  # 1. Hide them from Launchpad
  # 2. Use third-party tools to hide them (requires disabling SIP)
  # 3. Remove them from Dock (configured above)
}
