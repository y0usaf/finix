_: {
  # Disable macOS bloatware and unnecessary services
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

    # Disable Spotlight keyboard shortcut (Cmd+Space)
    "com.apple.symbolichotkeys" = {
      "AppleSymbolicHotKeys" = {
        "64" = {
          "enabled" = false;
        };
      };
    };

    # Disable Spotlight indexing entirely (using Raycast instead)
    "com.apple.spotlight" = {
      "orderedItems" = [];
    };
  };

  # Note: You cannot fully remove system apps like FaceTime, Music, TV, etc.
  # due to System Integrity Protection (SIP). However, you can:
  # 1. Hide them from Launchpad
  # 2. Use third-party tools to hide them (requires disabling SIP)
  # 3. Remove them from Dock (configured in other modules)
}
