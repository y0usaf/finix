{...}: {
  imports = [
    ./debloat.nix
    ./keyboard.nix
    ./trackpad.nix
    ./finder.nix
    ./screenshot.nix
    ./performance.nix
  ];

  system = {
    # Set primary user for user-specific defaults
    primaryUser = "y0usaf";

    # Disable various system services and configure defaults
    defaults = {
      LaunchServices.LSQuarantine = false; # Disable "Are you sure you want to open this application?" dialog

      # Global animation and performance tweaks
      NSGlobalDomain = {
        _HIHideMenuBar = true; # Menu bar - hide entirely
      };

      # Dock settings - minimize visibility
      dock = {
        autohide = true;
        autohide-delay = 0.0;
        show-recents = false;
        static-only = true; # Only show open applications
        tilesize = 16; # Very small icon size
      };
    };
  };

  # Disable Siri system-wide
  system.defaults.CustomSystemPreferences = {
    "com.apple.assistant.support" = {
      "Assistant Enabled" = 0;
    };
  };
}
